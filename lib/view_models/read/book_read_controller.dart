import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:storymate/services/api_service.dart';
import 'package:storymate/services/text_pagination_service.dart';
import 'package:storymate/views/read/book_more_page.dart';

import '../../models/highlight.dart';

class BookReadController extends GetxController {
  final ApiService apiService = ApiService();

  RxList<String> pages = <String>[].obs; // 페이지 목록
  RxInt currentPage = 0.obs; // 현재 페이지
  RxSet<int> bookmarks = <int>{}.obs; // 북마크 저장
  RxMap<int, int> bookmarkIds = <int, int>{}.obs; // {page: bookmarkId} 매핑
  RxBool isUIVisible = true.obs; // 상단바/하단바 가시성
  RxDouble progress = 0.0.obs; // 진행률
  RxMap<int, List<Highlight>> highlightsPerPage = <int, List<Highlight>>{}.obs;

  /// 책 데이터 초기화 (북마크 & 하이라이트 불러오기)
  Future<void> initializeBookData(int bookId) async {
    try {
      await Future.wait([
        fetchBookmarks(bookId), // 북마크 불러오기
        fetchHighlights(bookId), // 하이라이트 불러오기
      ]);

      print("[DEBUG] 책 데이터 초기화 완료! (북마크 & 하이라이트 불러옴)");
    } catch (e) {
      print("[ERROR] 책 데이터 초기화 중 오류 발생: $e");
    }
  }

  /// 책 읽기 진행도 업데이트 (API 연동)
  Future<void> updateReadingProgress(int bookId) async {
    if (pages.isEmpty) return;

    int progress = ((currentPage.value + 1) / pages.length * 100)
        .toInt(); // 100% 기준 진행도 계산
    try {
      await apiService.markBookAsRead(bookId, progress);
      print("[DEBUG] 책 진행도 업데이트 완료: $progress%");
    } catch (e) {
      print("[ERROR] 책 진행도 업데이트 중 오류 발생: $e");
    }
  }

  // 이전 페이지로 이동 (책 읽기 중단 시 진행도 저장)
  void goToPreviousPage(int bookId) async {
    if (currentPage.value > 0) {
      currentPage.value--;
      updateProgress();
      await updateReadingProgress(bookId); // 진행도 저장
    } else {
      Get.snackbar('알림', '첫 페이지입니다.');
    }
  }

  // 다음 페이지로 이동 (마지막 페이지일 경우 진행도 저장)
  void goToNextPage(int bookId) async {
    if (currentPage.value < pages.length - 1) {
      currentPage.value++;
      updateProgress();
      await updateReadingProgress(bookId); // 진행도 저장
    } else {
      Get.snackbar('알림', '마지막 페이지입니다.');
      await updateReadingProgress(bookId); // 마지막 페이지 읽음 표시
    }
  }

  // 뒤로 가기 (책 읽기 중단 시 진행도 저장)
  void goBack(int bookId) async {
    await updateReadingProgress(bookId); // 진행도 저장 후 종료
    resetBookData(); // 상태 초기화
    Get.back();
  }

  // 책 데이터를 초기화하는 메서드
  void resetBookData() {
    pages.clear(); // 페이지 목록 비우기
    currentPage.value = 0; // 현재 페이지 초기화
    progress.value = 0.0; // 진행률 초기화
    bookmarks.clear(); // 북마크 초기화
    bookmarkIds.clear(); // 북마크 ID 초기화
    highlightsPerPage.clear(); // 하이라이트 초기화
    print("[DEBUG] 책 데이터 초기화 완료: 새 파일 데이터를 읽을 준비 완료");
  }

  /// 특정 책의 하이라이트 목록 불러오기 (API 연동)
  Future<void> fetchHighlights(int bookId) async {
    try {
      List<Map<String, dynamic>> fetchedHighlights =
          await apiService.getBookHighlights(bookId);
      highlightsPerPage.clear();

      for (var highlight in fetchedHighlights) {
        int id = highlight["id"]; // 하이라이트 ID
        int page = highlight["pageNumber"] - 1; // 서버에서 받은 페이지 (currentPage 기준)
        int startPosition = highlight["startPosition"]; // 시작 Offset (텍스트 내 인덱스)
        int endPosition = highlight["endPosition"]; // 끝 Offset
        String paragraph = highlight["paragraph"]; // 하이라이트된 문장

        highlightsPerPage.update(
          page,
          (existing) => [
            ...existing,
            Highlight(
              id: id, // 하이라이트 ID 추가
              startOffset: startPosition, // 서버의 position을 Offset으로 사용
              endOffset: endPosition,
              content: paragraph, // 하이라이트된 텍스트 저장
            ),
          ],
          ifAbsent: () => [
            Highlight(
              id: id,
              startOffset: startPosition,
              endOffset: endPosition,
              content: paragraph,
            ),
          ],
        );
      }
      highlightsPerPage.refresh();
      print("[DEBUG] 하이라이트 목록 업데이트 완료");
    } catch (e) {
      print("[ERROR] 하이라이트 목록 불러오기 실패: $e");
    }
  }

  /// 하이라이트 추가 (API 연동)
  Future<void> addHighlight(
      int bookId, int startOffset, int endOffset, String content) async {
    try {
      int page = currentPage.value + 1; // 현재 페이지 번호 사용

      await apiService.addBookHighlights(
          bookId, page, startOffset, endOffset, content);

      // API에서 최신 하이라이트 목록 불러와 UI 업데이트
      await fetchHighlights(bookId);

      print("[DEBUG] 하이라이트 추가 완료: $content");
    } catch (e) {
      print("[ERROR] 하이라이트 추가 중 오류 발생: $e");
    }
  }

  /// 하이라이트 삭제 (API 연동)
  Future<void> removeHighlight(int bookId, int highlightId) async {
    try {
      await apiService.deleteBookHighlights(bookId, highlightId);

      // API에서 최신 하이라이트 목록 불러와 UI 업데이트
      await fetchHighlights(bookId);

      print("[DEBUG] 하이라이트 삭제 완료 (ID: $highlightId)");
    } catch (e) {
      print("[ERROR] 하이라이트 삭제 중 오류 발생: $e");
    }
  }

  /// 현재 페이지의 하이라이트 목록 가져오기
  List<Highlight> getHighlightsForCurrentPage() {
    return highlightsPerPage[currentPage.value] ?? [];
  }

  /// 특정 책의 북마크 목록 불러오기 (bookmarkId 포함)
  Future<void> fetchBookmarks(int bookId) async {
    try {
      List<Map<String, dynamic>> fetchedBookmarks =
          await apiService.getBookBookmarks(bookId);

      bookmarks.clear();
      bookmarkIds.clear();

      for (var bookmark in fetchedBookmarks) {
        int bookmarkId = bookmark['id'];
        int page = bookmark['position'];

        bookmarks.add(page);
        bookmarkIds[page] = bookmarkId;
      }

      print("[DEBUG] 북마크 목록 불러오기 완료: $bookmarkIds");
    } catch (e) {
      print("[ERROR] 북마크 목록 불러오기 실패: $e");
    }
  }

  /// 현재 페이지가 북마크 되어 있는지 여부 확인
  bool isBookmarked() {
    return bookmarks.contains(currentPage.value + 1);
  }

  /// 북마크 추가 또는 삭제 (북마크 여부에 따라 다르게 동작)
  Future<void> toggleBookmark(int bookId) async {
    int page = currentPage.value + 1;

    if (isBookmarked()) {
      await removeBookmark(bookId, page);
    } else {
      await addBookmark(bookId, page);
    }
  }

  /// 북마크 추가 (API 호출 후 최신 목록 조회)
  Future<void> addBookmark(int bookId, int page) async {
    try {
      await apiService.addBookBookmarks(bookId, page);

      // 북마크 추가 후 최신 목록 다시 조회하여 bookmarkId 매핑
      await fetchBookmarks(bookId);

      Get.snackbar('알림', '북마크가 설정되었습니다.');
      print("[DEBUG] 북마크 추가 완료: p.$page");
    } catch (e) {
      print("[ERROR] 북마크 추가 중 오류 발생: $e");
    }
  }

  /// 북마크 삭제 (bookmarkId 활용)
  Future<void> removeBookmark(int bookId, int page) async {
    try {
      if (!bookmarkIds.containsKey(page)) {
        print("[ERROR] 해당 페이지의 bookmarkId를 찾을 수 없음.");
        return;
      }

      int bookmarkId = bookmarkIds[page]!;
      await apiService.deleteBookBookmarks(bookId, bookmarkId);

      bookmarks.remove(page);
      bookmarkIds.remove(page);

      Get.snackbar('알림', '북마크가 해제되었습니다.');
      print("[DEBUG] 북마크 삭제 완료: p.$page (bookmarkId: $bookmarkId)");
    } catch (e) {
      print("[ERROR] 북마크 삭제 중 오류 발생: $e");
    }
  }

  // 책 파일 로드 (초기 데이터 로드 포함)
  Future<void> loadBook(String filePath, double screenWidth,
      double screenHeight, TextStyle textStyle, int bookId) async {
    if (pages.isNotEmpty) {
      print("[DEBUG] 파일이 이미 로드되어 있습니다. 재로드를 방지합니다.");
      return; // 이미 로드된 경우 재로드 방지
    }

    try {
      final String rawContent = await rootBundle.loadString(filePath);
      final String processedContent = preprocessText(rawContent); // 전처리 추가
      pages.value =
          paginateText(processedContent, screenWidth, screenHeight, textStyle);
      updateProgress();

      // 초기 데이터 로드 (북마크 & 하이라이트)
      await initializeBookData(bookId);

      // 파일 로드 후 진행도 업데이트
      await updateReadingProgress(bookId);
      print("[DEBUG] 파일 로드 및 진행도 업데이트 완료");
    } catch (e) {
      Get.snackbar('Error', '파일을 읽는 데 실패했습니다: $e');
    }
  }

  /// 특정 페이지의 미리보기 내용 가져오기
  String getPagePreview(int position) {
    if (pages.isNotEmpty && position < pages.length) {
      return pages[position].substring(0, 100); // 앞 100자만 미리보기로 제공
    }
    return "미리보기를 불러올 수 없습니다.";
  }

  String preprocessText(String text) {
    text = text.replaceAll('\n', ' ');
    text = text.replaceAll(RegExp(r'\s{3,}'), '\n\n');
    return text.trim();
  }

  // 페이지 진행률 업데이트
  void updateProgress() {
    if (pages.isNotEmpty) {
      progress.value = (currentPage.value + 1) / pages.length;
    }
  }

  // UI 가시성 토글
  void toggleUIVisibility() {
    isUIVisible.value = !isUIVisible.value;
  }

  // 첫 페이지로 리셋
  void resetToFirstPage() {
    currentPage.value = 0;
    updateProgress();
  }

  // 더보기 버튼 클릭 시
  void toMorePage(String title, int bookId) {
    Get.to(
      BookMorePage(),
      arguments: {
        'title': title,
        'bookId': bookId,
      },
    );
  }
}
