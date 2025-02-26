import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:storymate/components/theme.dart';
import 'package:storymate/view_models/chat/quiz_controller.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizController controller = Get.put(QuizController());

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 퀴즈 종료 여부 다이얼로그
        bool shouldExit = await _showExitConfirmationDialog(context);
        return shouldExit;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: Text(
            "퀴즈 풀기",
            style: TextStyle(fontFamily: 'Jua'),
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 모든 퀴즈 유형을 아코디언 형태로 보여줌
                  ...List.generate(controller.quizList.length, (index) {
                    var quiz = controller.quizList[index];
                    var quizType = quiz["type"];
                    var question = quiz["question"];

                    if (quizType == "multiple_choice") {
                      question = question.split('1.')[0].trim();
                    }

                    return ExpansionTile(
                      key: ValueKey("$quizType-$index"),
                      title: Text(
                        "${quizType.toUpperCase()} 퀴즈",
                        style: TextStyle(
                          fontFamily: 'Jua',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 문제 출력
                              Text(
                                "문제: $question",
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontFamily: 'Jua',
                                ),
                              ),
                              SizedBox(height: 20.h),

                              // 퀴즈 유형별 입력 위젯
                              _buildQuizInput(quizType, index),

                              SizedBox(height: 20.h),

                              // 제출 버튼
                              Center(
                                child: Obx(
                                  () => ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          controller.isAnswerProvided(index)
                                              ? AppTheme.primaryColor
                                              : Colors.grey,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20.w, vertical: 10.h),
                                    ),
                                    onPressed:
                                        controller.isAnswerProvided(index)
                                            ? () async {
                                                await controller.submitQuiz(
                                                    context,
                                                    index); // 퀴즈 제출 후 실행 완료 대기
                                              }
                                            : null,
                                    child: Text(
                                      "제출하기",
                                      style: TextStyle(
                                        fontFamily: 'Jua',
                                        color: Colors.white,
                                        fontSize: 18.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // 퀴즈 유형별 위젯 반환
  Widget _buildQuizInput(String quizType, int index) {
    switch (quizType) {
      case "ox":
        return _buildOXQuiz(index);
      case "multiple_choice":
        return _buildMultipleChoiceQuiz(index);
      case "essay":
        return _buildEssayQuiz(index);
      default:
        return Text("지원하지 않는 퀴즈 형식입니다.");
    }
  }

  // OX 퀴즈 위젯
  Widget _buildOXQuiz(int index) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => controller.oxAnswers[index] = 1,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  controller.oxAnswers[index] == 1 ? Colors.green : Colors.grey,
            ),
            child: Text(
              "O",
              style: TextStyle(
                fontFamily: 'Jua',
                color: Colors.white,
                fontSize: 20.sp,
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () => controller.oxAnswers[index] = 0,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  controller.oxAnswers[index] == 0 ? Colors.red : Colors.grey,
            ),
            child: Text(
              "X",
              style: TextStyle(
                fontFamily: 'Jua',
                color: Colors.white,
                fontSize: 20.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 객관식 퀴즈 위젯
  Widget _buildMultipleChoiceQuiz(int index) {
    String fullQuestion = controller.quizList[index]["question"];
    List<String> options = controller.parseOptionsFromQuestion(fullQuestion);
    int selectedAnswer = controller.mcqAnswers[index] ?? -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(options.length, (optionIndex) {
        bool isSelected = selectedAnswer == optionIndex;

        return GestureDetector(
          onTap: () {
            setState(() {
              controller.mcqAnswers[index] = optionIndex;
            });
          },
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8.h),
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey,
                width: 2,
              ),
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.white,
            ),
            child: Text(
              '${optionIndex + 1}. ${options[optionIndex]}',
              style: TextStyle(
                fontFamily: 'Jua',
                fontSize: 18.sp,
                color: isSelected ? AppTheme.primaryColor : Colors.black,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEssayQuiz(int index) {
    String question = controller.quizList[index]["question"];
    String responseMessage = controller.essayResponses[index] ?? '';

    // 기존 컨트롤러가 없다면 생성
    if (!controller.essayControllers.containsKey(index)) {
      controller.essayControllers[index] =
          TextEditingController(text: controller.essayAnswers[index] ?? '');
    }

    TextEditingController essayController = controller.essayControllers[index]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: essayController,
          decoration: InputDecoration(
            hintText: "정답을 입력하세요",
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          onChanged: (value) {
            controller.essayAnswers[index] = value; // 답변 저장
          },
        ),
        SizedBox(height: 15.h),
        if (responseMessage.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 20.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.primaryColor,
                  size: 24.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    responseMessage,
                    style: TextStyle(
                      fontFamily: 'Jua',
                      fontSize: 16.sp,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 퀴즈 종료 확인 다이얼로그
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    bool shouldExit = false;

    String additionalMessage = "";
    if (controller.isQuizRetake.value) {
      additionalMessage = "\n\n이후 퀴즈 재도전 시 메시지 개수가 1개 차감됩니다.";
    }

    await Get.dialog(
      Dialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "퀴즈를 종료하시겠습니까?",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              Text(
                "퀴즈를 중단하면 대화 화면으로 돌아갑니다.$additionalMessage",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 16.sp,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      shouldExit = false;
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      padding: EdgeInsets.symmetric(
                          vertical: 12.h, horizontal: 12.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "계속하기",
                      style: TextStyle(
                        fontFamily: 'Jua',
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      shouldExit = true;
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: EdgeInsets.symmetric(
                          vertical: 12.h, horizontal: 12.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "중단하기",
                      style: TextStyle(
                        fontFamily: 'Jua',
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    return shouldExit;
  }
}
