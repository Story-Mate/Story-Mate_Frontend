import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:storymate/components/theme.dart';
import 'package:storymate/services/api_service.dart';

class QuizController extends GetxController {
  final ApiService apiService = ApiService();

  var quizList = <Map<String, dynamic>>[].obs; // 모든 퀴즈 데이터 저장
  var currentQuizIndex = 0.obs; // 현재 퀴즈 인덱스
  var isLoading = true.obs;
  var isSubmitting = false.obs;

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

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments != null) {
      characterName = Get.arguments["characterName"] ?? "";
      bookTitle = Get.arguments["bookTitle"] ?? "";
    } else {
      characterName = "UnknownCharacter";
      bookTitle = "UnknownBook";
    }

    fetchAllQuizzes();
  }

  // 모든 퀴즈 데이터 요청
  Future<void> fetchAllQuizzes() async {
    isLoading.value = true;

    List<String> quizTypes = ["ox", "multiple_choice", "essay"];

    for (String type in quizTypes) {
      var data = await apiService.fetchQuizData(characterName, bookTitle, type);
      if (data != null) {
        Map<String, dynamic>? quizData = data["data"];
        if (quizData != null) {
          quizList.add({
            "type": type,
            "question": quizData["quiz"],
          });
          print("추가된 퀴즈 데이터: ${quizData["quiz"]} | 유형: $type");
        } else {
          print("서버에서 해당 유형의 퀴즈 데이터를 받지 못했습니다: $type");
        }
      }
    }

    print("전체 퀴즈 데이터 목록: $quizList");

    isLoading.value = false;
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
      // 서버로 답안 제출 (GET 요청 유지)
      var response = await apiService.submitQuizAnswer(
          characterName, bookTitle, quizType, userAnswer);

      if (response != null && response["statusCode"] == 200) {
        print("서버 응답 전체 데이터: $response");

        String resultMessage =
            response["data"]["response"]?.toString() ?? "응답 데이터가 없습니다.";
        String essayResult = "";
        String correctStatus = response["data"]["correct"]?.toString() ?? "";

        // 메세지 개수 증가 안내 메시지 추가
        String messageIncrement = "";
        if (quizType == "ox" && correctStatus == "true") {
          messageIncrement = "메세지 개수가 1개 추가되었습니다!";
        } else if (quizType == "multiple_choice" && correctStatus == "true") {
          messageIncrement = "메세지 개수가 2개 추가되었습니다!";
        } else if (quizType == "essay") {
          if (correctStatus == "O") {
            essayResult = "정답입니다!";
            messageIncrement = "메세지 개수가 3개 추가되었습니다!";
          } else if (correctStatus == "C") {
            essayResult = "거의 맞췄어요! 좀 더 생각해보세요.";
            messageIncrement = "메세지 개수가 1개 추가되었습니다!";
          } else {
            essayResult = "오답입니다. 다시 생각해보세요.";
          }
        }

        if (quizType == "essay") {
          // 다이얼로그에 결과 및 메세지 증가 안내 표시
          showResultDialog(context, "$essayResult\n$messageIncrement");

          // essayResponse.value = resultMessage;
          essayResponses[index] = resultMessage;
          isEssaySubmitting.value = false;

          // 제출 후 입력 필드 초기화
          essayControllers[index]?.clear();
        } else {
          showResultDialog(context, "$resultMessage\n$messageIncrement");
        }
      } else {
        print("퀴즈 제출 실패");
        // 서버 응답이 실패했을 경우
        showErrorDialog(context, "서버 오류가 발생했습니다. 다시 시도해주세요.");
      }
    } catch (e) {
      // 네트워크 오류나 예외 발생 시
      print("퀴즈 제출 중 오류 발생: $e");
      showErrorDialog(context, "서버 연결 중 오류가 발생했습니다. 네트워크 상태를 확인하세요.");
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
