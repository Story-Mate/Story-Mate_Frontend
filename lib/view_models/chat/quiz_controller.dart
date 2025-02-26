import 'dart:async';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storymate/components/theme.dart';
import 'package:storymate/services/api_service.dart';
import 'package:storymate/views/mypage/my_page.dart';

class QuizController extends GetxController {
  final ApiService apiService = ApiService();
  late SharedPreferences prefs;

  var quizList = <Map<String, dynamic>>[].obs; // 모든 퀴즈 데이터 저장
  var isLoading = true.obs;
  var isSubmitting = false.obs;

  var previousSubmissions = <String, bool>{}.obs;
  var messageCount = 0.obs;

  var isEssaySubmitting = false.obs; // 에세이 제출 로딩 상태
  var essayResponse = ''.obs; // 에세이 응답 메시지
  var essayAnswer = ''.obs; // 에세이 입력값 관리

  String characterName = "";
  String bookTitle = "";

  var question = "".obs; // Rx 변수로 변경
  var quizType = "".obs; // Rx 변수로 변경

  var essayControllers =
      <int, TextEditingController>{}.obs; // 각 에세이 퀴즈별 컨트롤러 저장

  var oxAnswers = <int, int>{}.obs; // OX 퀴즈 답변 저장 (index, 답변값)
  var mcqAnswers = <int, int>{}.obs; // 객관식 답변 저장 (index, 답변 인덱스)
  var essayAnswers = <int, String>{}.obs; // 에세이 답변 저장 (index, 텍스트)
  var essayResponses = <int, String>{}.obs; // 에세이 서버 응답 저장

  var isQuizRetake = false.obs; // 사용자의 퀴즈 제출 여부 저장

  @override
  void onInit() async {
    super.onInit();

    if (Get.arguments != null) {
      characterName = Get.arguments["characterName"] ?? "";
      bookTitle = Get.arguments["bookTitle"] ?? "";
    } else {
      characterName = "UnknownCharacter";
      bookTitle = "UnknownBook";
    }

    prefs = await SharedPreferences.getInstance();
    Get.put(prefs);

    await fetchUserInfo(); // 사용자 정보 조회
    checkQuizSubmissionStatus();
  }

  /// 회원 정보 조회 API 호출
  Future<void> fetchUserInfo() async {
    try {
      final userData = await apiService.fetchUserInfo();

      if (userData != null) {
        messageCount.value = userData["messageCount"] ?? 0;

        print("회원 정보 조회 성공: 메시지 개수=${messageCount.value}");
      } else {
        print("회원 정보 조회 실패");
      }
    } catch (e) {
      print("회원 정보 조회 중 오류 발생: $e");
    }
  }

  /// 메시지가 부족한 경우 안내창 표시
  Future<void> showNoMessageAlert() async {
    await Get.dialog(
      Dialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "메시지 부족",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              Text(
                "잔여 메시지가 부족하여 퀴즈 재도전이 불가합니다.\n충전 후 이용해주세요.",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 18,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.off(MyPage()); // 마이페이지로 이동
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: Text(
                  "충전하러 가기",
                  style: TextStyle(
                    fontFamily: 'Jua',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 사용자의 퀴즈 제출 여부 확인 (각 타입별 저장)
  Future<void> checkQuizSubmissionStatus() async {
    List<String> quizTypes = ["ox", "multiple_choice", "essay"];

    isLoading.value = true;
    quizList.clear();

    for (String type in quizTypes) {
      if (hasQuizBeenSubmitted(type)) {
        await restartQuiz(type); // 해당 퀴즈 타입만 퀴즈 재도전 API 호출
      } else {
        await fetchQuiz(type); // 기존 방식으로 퀴즈 불러오기
      }
    }

    isLoading.value = false;
  }

  /// 특정 타입의 퀴즈 데이터 요청
  Future<void> fetchQuiz(String quizType) async {
    var data =
        await apiService.fetchQuizData(characterName, bookTitle, quizType);
    if (data != null) {
      Map<String, dynamic>? quizData = data["data"];
      if (quizData != null) {
        quizList.add({
          "type": quizType,
          "question": quizData["quiz"],
        });

        // 퀴즈 목록 정렬 유지
        quizList.sort((a, b) {
          List<String> order = ["ox", "multiple_choice", "essay"];
          return order.indexOf(a["type"]).compareTo(order.indexOf(b["type"]));
        });

        print("불러온 퀴즈 데이터: ${quizData["quiz"]} | 유형: $quizType");
      } else {
        print("서버에서 해당 유형의 퀴즈 데이터를 받지 못했습니다: $quizType");
      }
    }
  }

  /// 특정 타입의 퀴즈 재도전 API 호출 (메시지 1개 차감)
  Future<void> restartQuiz(String quizType) async {
    if (messageCount.value == 0) {
      await showNoMessageAlert(); // 메시지가 부족하면 안내창 띄우고 종료
      return;
    }

    print("퀴즈 재도전 요청: $quizType");

    var response =
        await apiService.retakeQuiz(characterName, bookTitle, quizType);
    if (response != null && response["data"] != null) {
      print("재도전한 퀴즈 데이터 수신 완료: ${response["data"]["quiz"]}");

      // 기존 리스트에서 해당 타입의 퀴즈 제거 후 갱신
      quizList.removeWhere((quiz) => quiz["type"] == quizType);
      quizList.add({
        "type": quizType,
        "question": response["data"]["quiz"],
      });

      print("퀴즈 목록 갱신 완료: ${quizList.length}개 존재");

      // 퀴즈 목록 정렬 유지
      quizList.sort((a, b) {
        List<String> order = ["ox", "multiple_choice", "essay"];
        return order.indexOf(a["type"]).compareTo(order.indexOf(b["type"]));
      });

      saveQuizSubmission(quizType);
      await fetchUserInfo();
    } else {
      print("퀴즈 재도전 실패: 서버 응답 없음");
    }
  }

  /// 특정 퀴즈 타입의 제출 여부 저장
  Future<void> saveQuizSubmission(String quizType) async {
    String key = "quiz_submitted_${bookTitle}_${characterName}_$quizType";
    await prefs.setBool(key, true);
  }

  /// 특정 퀴즈 타입이 제출되었는지 확인
  bool hasQuizBeenSubmitted(String quizType) {
    String key = "quiz_submitted_${bookTitle}_${characterName}_$quizType";
    return prefs.getBool(key) ?? false;
  }

  /// 퀴즈 재도전 안내 다이얼로그
  Future<bool> showRetakeAlertDialog() async {
    Completer<bool> completer = Completer<bool>();

    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.backgroundColor, // 다이얼로그 배경색
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // 둥근 모서리 설정
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용만큼만 크기 설정
            mainAxisAlignment: MainAxisAlignment.spaceAround, // 요소 간 공간 배분
            children: [
              // 다이얼로그 제목
              Text(
                "퀴즈 재도전",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // 텍스트 색상
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),

              // 안내 메시지
              Text(
                "퀴즈 재도전을 진행하여\n메시지 개수가 1개 차감되었습니다.\n\n현재 잔여 메시지: ${messageCount.value}개",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 18,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),

              // 확인 버튼
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  completer.complete(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor, // 버튼 색상 설정
                ),
                child: Text(
                  "확인",
                  style: TextStyle(
                    fontFamily: 'Jua',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return completer.future;
  }

  List<String> parseOptionsFromQuestion(String question) {
    // 문제와 선택지를 분리하기 위한 정규 표현식 사용
    final optionsRegex = RegExp(r'(\d+)\.(.*?)($|\n)');

    List<String> options = [];
    Iterable<RegExpMatch> matches = optionsRegex.allMatches(question);

    for (final match in matches) {
      options.add(match.group(2)!.trim());
    }

    return options;
  }

  bool isAnswerProvided(int index) {
    String quizType = quizList[index]["type"];

    if (quizType == "ox") {
      return oxAnswers.containsKey(index) && oxAnswers[index] != -1;
    } else if (quizType == "multiple_choice") {
      return mcqAnswers.containsKey(index) && mcqAnswers[index] != -1;
    } else if (quizType == "essay") {
      return essayAnswers.containsKey(index) &&
          essayAnswers[index]!.trim().isNotEmpty;
    }
    return false;
  }

  // 퀴즈 제출 및 결과 확인
  Future<void> submitQuiz(BuildContext context, index) async {
    if (isSubmitting.value) return;

    isSubmitting.value = true;

    String quizType = quizList[index]["type"];
    String userAnswer = "";

    if (quizType == "ox") {
      int? answer = oxAnswers[index];
      userAnswer = answer == 1 ? "O" : "X";
    } else if (quizType == "multiple_choice") {
      int? answer = mcqAnswers[index];
      userAnswer = (answer! + 1).toString(); // 선택한 객관식 인덱스 + 1
    } else if (quizType == "essay") {
      userAnswer = essayAnswers[index] ?? "";
    }

    try {
      // 이미 제출한 퀴즈라면, 먼저 퀴즈 재도전 수행 후 안내창 띄우기
      if (previousSubmissions[quizType] == true) {
        await restartQuiz(quizType); // 퀴즈 재도전 수행
        bool confirmed = await showRetakeAlertDialog(); // 확인 버튼 클릭 대기

        if (!confirmed) {
          isSubmitting.value = false;
          return; // 사용자가 확인하지 않으면 제출 중단
        }
      }

      // 서버로 답안 제출 (GET 요청 유지)
      var response = await apiService.submitQuizAnswer(
          characterName, bookTitle, quizType, userAnswer);

      if (response != null && response["statusCode"] == 200) {
        await fetchUserInfo();

        print("서버 응답 전체 데이터: $response");

        String resultMessage =
            response["data"]["response"]?.toString() ?? "응답 데이터가 없습니다.";
        String essayResult = "";
        String correctStatus = response["data"]["correct"]?.toString() ?? "";

        // 메시지 개수 증가 안내 메시지 추가
        String messageIncrement = "";
        if (quizType == "ox" && correctStatus == "true") {
          messageIncrement = "메시지 개수가 3개 추가되었습니다!";
        } else if (quizType == "multiple_choice" && correctStatus == "true") {
          messageIncrement = "메시지 개수가 3개 추가되었습니다!";
        } else if (quizType == "essay") {
          if (correctStatus == "O") {
            essayResult = "정답입니다!";
            messageIncrement = "메시지 개수가 5개 추가되었습니다!";
          } else if (correctStatus == "C") {
            essayResult = "거의 맞췄어요! 좀 더 생각해보세요.";
            messageIncrement = "메시지 개수가 3개 추가되었습니다!";
          } else {
            essayResult = "오답입니다. 다시 생각해보세요.";
          }
        }

        if (quizType == "essay") {
          // 다이얼로그에 결과 및 메시지 증가 안내 표시
          showResultDialog(context,
              "$essayResult\n$messageIncrement\n잔여 메시지: ${messageCount.value}");

          // essayResponse.value = resultMessage;
          essayResponses[index] = resultMessage;
          isEssaySubmitting.value = false;

          // 제출 후 입력 필드 초기화
          essayControllers[index]?.clear();
        } else {
          showResultDialog(context,
              "$resultMessage\n$messageIncrement\n잔여 메시지: ${messageCount.value}");
        }

        // 해당 퀴즈 타입이 한 번 제출됨을 저장
        previousSubmissions[quizType] = true;
        saveQuizSubmission(quizType);
      } else {
        print("퀴즈 제출 실패");
        // 서버 응답이 실패했을 경우
        showErrorDialog(context, "서버 오류가 발생했습니다.\n다시 시도해주세요.");
      }
    } catch (e) {
      // 네트워크 오류나 예외 발생 시
      print("퀴즈 제출 중 오류 발생: $e");
      showErrorDialog(context, "서버 연결 중 오류가 발생했습니다.\n네트워크 상태를 확인하세요.");
    }

    isSubmitting.value = false;
  }

  // 서버 오류 다이얼로그
  void showErrorDialog(BuildContext context, String message) {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.backgroundColor, // 다이얼로그 배경색
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // 둥근 모서리 설정
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용만큼만 크기 설정
            mainAxisAlignment: MainAxisAlignment.spaceAround, // 요소 간 공간 배분
            children: [
              // 오류 메시지 출력
              Text(
                "오류 발생",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red, // 오류 메시지 색상
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              Text(
                message,
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 18,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              // 확인 버튼
              ElevatedButton(
                onPressed: () {
                  Get.back(); // 다이얼로그 닫기
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor, // 버튼 색상 설정
                ),
                child: Text(
                  "확인",
                  style: TextStyle(
                    fontFamily: 'Jua',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 결과 다이얼로그
  void showResultDialog(BuildContext context, String message) {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.backgroundColor, // 다이얼로그 배경색
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // 둥근 모서리 설정
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용만큼만 크기 설정
            mainAxisAlignment: MainAxisAlignment.spaceAround, // 요소 간 공간 배분
            children: [
              // 다이얼로그 제목
              Text(
                message,
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // 텍스트 색상
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 10.h,
              ),
              // 확인 버튼
              ElevatedButton(
                onPressed: () {
                  Get.back(); // 다이얼로그 닫기
                  // moveToNextQuiz(context); // 콜백 실행
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor, // 버튼 색상 설정
                ),
                child: Text(
                  "확인",
                  style: TextStyle(
                    fontFamily: 'Jua',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
