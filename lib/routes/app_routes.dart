// 라우팅 관리

import 'package:get/get.dart';
import 'package:storymate/views/mypage/modify_info_page.dart';
import 'package:storymate/views/mypage/payment_fail_page.dart';
import 'package:storymate/views/mypage/payment_page.dart';
import 'package:storymate/views/mypage/payment_success_page.dart';
import 'package:storymate/views/onboarding/info_page.dart';
import 'package:storymate/views/onboarding/sign_in_page.dart';
import 'package:storymate/views/onboarding/sign_up_page.dart';
import 'package:storymate/views/onboarding/terms_detail_page.dart';
import 'package:storymate/views/onboarding/terms_page.dart';
import 'package:storymate/views/read/add_memo_page.dart';
import 'package:storymate/views/read/book_intro_page.dart';
import 'package:storymate/views/book_list_page.dart';
import 'package:storymate/views/read/book_read_page.dart';
import 'package:storymate/views/book_search_page.dart';
import 'package:storymate/views/home_page.dart';
import 'package:storymate/views/chat/character_selection_screen.dart';
import 'package:storymate/views/chat/chat_screen.dart';
import 'package:storymate/views/mypage/my_page.dart';

class AppRoutes {
  static const HOME = '/home';
  static const SIGNUP = '/sign_up';
  static const SIGNIN = '/sign_in';
  static const INFO = '/info';
  static const CHARACTER_SELECTION = '/character_selection';
  static const CHAT = '/chat';
  static const BOOK_LIST = '/book_list';
  static const BOOK_SEARCH = '/book_search';
  static const MEMO = '/memo';

  static final routes = [
    GetPage(
      name: HOME,
      page: () => HomePage(),
    ),
    // 카카오로 시작하기 (회원가입)
    GetPage(
      name: SIGNUP,
      page: () => SignUpPage(),
    ),
    // 카카오 로그인
    GetPage(
      name: SIGNIN,
      page: () => SignInPage(),
    ),
    // 약관 동의 화면
    GetPage(
      name: '/terms',
      page: () => TermsPage(),
      children: [
        // 약관 전문 화면
        GetPage(
          name: '/detail',
          page: () => TermsDetailPage(),
        ),
      ],
    ),
    // 내 정보 등록
    GetPage(
      name: INFO,
      page: () => InfoPage(),
    ),
    // 작품 목록 화면
    GetPage(
      name: BOOK_LIST,
      page: () => BookListPage(),
    ),
    // 작품 검색 화면
    GetPage(
      name: BOOK_SEARCH,
      page: () => BookSearchPage(),
    ),
    // 작품 소개 화면
    GetPage(
      name: '/book_intro',
      page: () => BookIntroPage(),
      children: [
        // 작품 읽기 화면
        GetPage(
          name: '/read',
          page: () => BookReadPage(),
        ),
      ],
    ),
    // 메모 작성창
    GetPage(
      name: MEMO,
      page: () => AddMemoPage(),
    ), // 캐릭터 선택 화면
    GetPage(
      name: CHARACTER_SELECTION,
      page: () => CharacterSelectionScreen(),
    ),
    // 채팅 화면
    GetPage(
      name: CHAT,
      page: () => ChatScreen(),
    ),
    // 마이페이지
    GetPage(
      name: '/my_page',
      page: () => MyPage(),
      children: [
        // 내 정보 수정
        GetPage(
          name: '/info',
          page: () => ModifyInfoPage(),
        ),
        GetPage(
          name: '/payments',
          page: () => PaymentPage(),
          children: [
            // 결제 성공 화면
            GetPage(
              name: '/success',
              page: () => PaymentSuccessPage(),
            ),
            // 결제 실패 화면
            GetPage(
              name: '/fail',
              page: () => PaymentFailPage(),
            ),
          ],
        ),
      ],
    ),
  ];
}
