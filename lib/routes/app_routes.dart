// 라우팅 관리

import 'package:get/get.dart';
import 'package:storymate/views/book_list_page.dart';
import 'package:storymate/views/book_search_page.dart';
import 'package:storymate/views/home_page.dart';

class AppRoutes {
  static const HOME = '/';

  static final routes = [
    GetPage(
      name: HOME,
      page: () => HomePage(),
    ),
    // 작품 목록 화면
    GetPage(
      name: '/book_list',
      page: () => BookListPage(),
    ),
    // 작품 검색 화면
    GetPage(
      name: '/book_search',
      page: () => BookSearchPage(),
    ),
  ];
}
