import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:storymate/components/custom_alert_dialog.dart';
import 'package:storymate/components/book_app_bar.dart';
import 'package:storymate/components/theme.dart';
import 'package:storymate/view_models/read/book_read_controller.dart';

import '../../models/highlight.dart';

class BookReadPage extends StatefulWidget {
  const BookReadPage({super.key});

  @override
  State<BookReadPage> createState() => _BookReadPageState();
}

class _BookReadPageState extends State<BookReadPage> {
  // final BookReadController controller = Get.put(BookReadController());
  final BookReadController controller = Get.find<BookReadController>();

  int? startSelection;
  int? endSelection;
  bool isSelecting = false;

  final textStyle =
      TextStyle(fontSize: 18.sp, height: 2.5.h, fontFamily: 'Nanum');

  @override
  Widget build(BuildContext context) {
    final BookReadController controller = Get.put(BookReadController());

    // Get.arguments로 전달받은 책 정보
    final arguments = Get.arguments as Map<String, dynamic>;
    final String title = arguments['title'] ?? '작품 제목';
    final int bookId = arguments['bookId'] ?? -1;

    // TXT 파일명 생성 (공백을 "_"로 변환하여 파일명 안전하게)
    final String fileName = '${title.replaceAll(RegExp(r'\s+'), '')}.txt';
    final String filePath = 'assets/$fileName';

    // 화면 크기 및 텍스트 스타일 설정
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height * 0.65.h;

    // 동적으로 책 파일 로드
    controller.loadBook(filePath, screenWidth, screenHeight, textStyle, bookId);

    return PopScope(
      canPop: false, // 뒤로 가기 방지
      onPopInvoked: (didPop) {
        if (didPop) return; // 뒤로 가기 요청 무시
      },
      child: Obx(() {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: controller.isUIVisible.value
              ? BookAppBar(
                  title: title,
                  onLeadingTap: () => controller.goBack(bookId),
                  isActionVisible: true,
                  onBookmarkTap: () {
                    controller.toggleBookmark(bookId);
                  }, // 북마크 탭 클릭 로직 필요
                  bookmarkActive: controller.bookmarks
                      .contains(controller.currentPage.value + 1),
                  onMoreTap: () =>
                      controller.toMorePage(title, bookId), // 더보기 탭 클릭 로직 필요
                )
              : AppBar(
                  forceMaterialTransparency: true,
                  toolbarHeight: 57.h,
                ),
          bottomNavigationBar: controller.isUIVisible.value
              ? Container(
                  width: MediaQuery.of(context).size.width,
                  height: 79.h,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 0.50.w,
                        strokeAlign: BorderSide.strokeAlignOutside,
                        color: Color(0xFFA2A2A2),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: 25.w, bottom: 20.h, right: 25.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 리셋 버튼
                        GestureDetector(
                          onTap: () async {
                            bool? result = await showDialog<bool>(
                              context: context,
                              builder: (context) => CustomAlertDialog(
                                  question: '처음부터 다시 읽으시겠습니까?'),
                            );
                            if (result == true) {
                              controller.resetToFirstPage(); // 첫 페이지로 이동
                            }
                          },
                          child: Icon(Icons.undo),
                        ),
                        // 페이지 정보와 프로그레스 바
                        Obx(
                          () => SizedBox(
                            width: 258.w,
                            child: Slider(
                              value: controller.pages.isEmpty
                                  ? 0
                                  : controller.currentPage.value.toDouble(),
                              min: 0,
                              max: (controller.pages.isEmpty
                                      ? 1
                                      : controller.pages.length - 1)
                                  .toDouble(),
                              divisions: controller.pages.isEmpty
                                  ? null
                                  : controller.pages.length - 1,
                              activeColor: AppTheme.primaryColor,
                              inactiveColor: Colors.grey.withOpacity(
                                  controller.pages.isEmpty ? 0.3 : 1.0),
                              onChanged: controller.pages.isEmpty
                                  ? null
                                  : (double value) {
                                      controller.currentPage.value =
                                          value.toInt();
                                      controller.updateProgress();
                                    },
                              label: controller.pages.isEmpty
                                  ? ''
                                  : '${controller.currentPage.value + 1}',
                            ),
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.currentPage.value + 1}/${controller.pages.length}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13.sp,
                              fontFamily: 'Nanum',
                              fontWeight: FontWeight.w400,
                              height: 1.33.h,
                              letterSpacing: -0.23.w,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
          floatingActionButton: FloatingActionButton(
            onPressed: _showHighlightGuide,
            backgroundColor: AppTheme.primaryColor,
            child: Icon(Icons.help_outline, color: Colors.white),
          ),
          body: GestureDetector(
            onTap: controller.toggleUIVisibility,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                // 오른쪽 -> 왼쪽 스와이프 (다음 페이지)
                controller.goToNextPage(bookId);
              } else if (details.primaryVelocity! > 0) {
                // 왼쪽 -> 오른쪽 스와이프 (이전 페이지)
                controller.goToPreviousPage(bookId);
              }
            },
            child: Obx(() {
              if (controller.pages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              } else {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText.rich(
                    _buildHighlightedText(bookId),
                    onSelectionChanged: (TextSelection selection, cause) {
                      if (selection.start != selection.end) {
                        setState(() {
                          startSelection = selection.start;
                          endSelection = selection.end;
                          isSelecting = true; // 드래그 시작
                        });
                      }
                    },
                    onTap: () {
                      if (isSelecting &&
                          startSelection != null &&
                          endSelection != null) {
                        _addHighlight(bookId);
                      }
                    },
                    style: textStyle,
                  ),
                );
              }
            }),
          ),
        );
      }),
    );
  }

  /// 선택된 부분을 즉시 하이라이트 처리하는 `TextSpan` 생성
  TextSpan _buildHighlightedText(int bookId) {
    String text = controller.pages[controller.currentPage.value];
    List<InlineSpan> spans = [];
    int currentIndex = 0;

    debugPrint("[DEBUG] 현재 페이지 길이: ${text.length}");

    try {
      // 기존 하이라이트 적용
      for (var highlight in controller.getHighlightsForCurrentPage()) {
        if (currentIndex < highlight.startOffset) {
          spans.add(TextSpan(
              text: text.substring(currentIndex, highlight.startOffset),
              style: textStyle));
        }

        final recognizer = LongPressGestureRecognizer()
          ..onLongPress = () => _showDeleteOption(bookId, highlight);

        spans.add(TextSpan(
          text: text.substring(highlight.startOffset, highlight.endOffset),
          style: textStyle.copyWith(backgroundColor: Colors.yellow),
          recognizer: recognizer,
        ));

        currentIndex = highlight.endOffset;
      }

      // 드래그 중인 영역을 즉시 반영하여 하이라이트
      if (startSelection != null &&
          endSelection != null &&
          isSelecting &&
          startSelection! < endSelection!) {
        if (currentIndex < startSelection!) {
          spans.add(TextSpan(
              text: text.substring(currentIndex, startSelection!),
              style: textStyle));
        }

        spans.add(TextSpan(
          text: text.substring(startSelection!, endSelection!),
          style: textStyle.copyWith(
              backgroundColor: Colors.yellow.withOpacity(0.5)),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _confirmAddHighlight(bookId),
        ));

        currentIndex = endSelection!;
      }

      if (currentIndex < text.length) {
        spans.add(
            TextSpan(text: text.substring(currentIndex), style: textStyle));
      }
    } catch (e) {
      debugPrint("[ERROR] 하이라이트 적용 중 오류 발생: $e");
    }

    return TextSpan(children: spans);
  }

  /// 하이라이트 추가 확인창 띄우기
  void _confirmAddHighlight(int bookId) async {
    bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(question: "이 부분을\n하이라이트로 저장하시겠습니까?");
      },
    );

    if (shouldSave == true) {
      _addHighlight(bookId);
    } else {
      setState(() {
        isSelecting = false; // 선택 취소
      });
    }
  }

  /// 하이라이트 추가 (선택한 텍스트의 Offset을 기반으로 API 호출)
  void _addHighlight(int bookId) {
    if (startSelection == null || endSelection == null) return;

    final text = controller.pages[controller.currentPage.value];

    // 선택한 문장을 기반으로 하이라이트 추가
    String selectedText = text.substring(startSelection!, endSelection!);
    int startOffset = startSelection!;
    int endOffset = endSelection!;

    debugPrint("[DEBUG] 하이라이트 추가 요청 - 선택된 텍스트: \"$selectedText\"");

    controller.addHighlight(bookId, startOffset, endOffset, selectedText);

    setState(() {
      isSelecting = false; // 드래그 종료
    });
  }

  /// 하이라이트 삭제 옵션창 띄우기
  void _showDeleteOption(int bookId, Highlight highlight) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          question: "이 하이라이트를 삭제하시겠습니까?",
        );
      },
    );

    if (shouldDelete == true) {
      _confirmDeleteHighlight(bookId, highlight);
    }
  }

  /// 하이라이트 삭제 (API 연동)
  void _confirmDeleteHighlight(int bookId, Highlight highlight) async {
    await controller.removeHighlight(bookId, highlight.id);
    setState(() {});
  }

  // 하이라이트 사용법
  void _showHighlightGuide() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundColor,
          title: Text(
            "하이라이트 사용법",
            style: TextStyle(
              fontFamily: 'Jua',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuideSection("📌 하이라이트 추가 방법", [
                "1. 텍스트를 길게 드래그하여 원하는 부분을 선택하세요.",
                "2. 선택된 부분을 클릭하면 하이라이트 저장 여부를 묻는 창이 나타납니다.",
                "3. '예'을 선택하면 하이라이트가 추가됩니다."
              ]),
              SizedBox(height: 16),
              _buildGuideSection("🗑️ 하이라이트 삭제 방법", [
                "1. 기존에 하이라이트된 텍스트를 길게 눌러주세요.",
                "2. 삭제 여부를 묻는 창이 나타나면 '예'를 선택하세요."
              ]),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "닫기",
                style: TextStyle(
                  fontFamily: 'Jua',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 안내 섹션을 만드는 위젯
  Widget _buildGuideSection(String title, List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Jua',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        ...steps.map(
          (step) => Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              step,
              style: TextStyle(
                fontFamily: 'Jua',
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
