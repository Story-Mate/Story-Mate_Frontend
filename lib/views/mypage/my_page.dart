import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:storymate/components/custom_alert_dialog.dart';
import 'package:storymate/components/custom_bottom_bar.dart';
import 'package:storymate/components/custom_card.dart';
import 'package:storymate/components/theme.dart';
import 'package:storymate/services/api_service.dart';
import 'package:storymate/view_models/mypage/my_controller.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with RouteAware {
  final MyController controller = Get.put(MyController());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // 화면에 다시 진입했을 때 데이터 새로고침
  @override
  void didPopNext() {
    controller.fetchUserInfo(); // 데이터 새로고침
    controller.fetchReadingBooks();
    controller.fetchFinishedBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          '마이페이지',
          style: TextStyle(
            color: Colors.black,
            fontSize: 25.sp,
            fontFamily: 'Jua',
            fontWeight: FontWeight.w400,
            height: 0.80.h,
            letterSpacing: -0.23.w,
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(currentIndex: 2),
      body: Column(
        children: [
          Container(
            height: 0.5.h,
            color: Color(0xffa2a2a2),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 25.w),
              child: ListView(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 25.w, top: 30.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 사용자 이름 (동적 데이터 적용)
                            Obx(() => Text(
                                  '${controller.userName.value}님',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 25.sp,
                                    fontFamily: 'Jua',
                                    fontWeight: FontWeight.w400,
                                    height: 0.80.h,
                                    letterSpacing: -0.23.w,
                                  ),
                                )),
                            SizedBox(height: 8.h),
                            // 생년월일 (동적 데이터 적용)
                            Obx(() => Text(
                                  controller.userBirth.value,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.sp,
                                    fontFamily: 'Jua',
                                    fontWeight: FontWeight.w400,
                                    height: 1.h,
                                    letterSpacing: -0.23.w,
                                  ),
                                )),
                          ],
                        ),
                        // 내 정보 수정 버튼
                        GestureDetector(
                          onTap: () {
                            Get.toNamed('/my_page/info');
                          },
                          child: Container(
                            width: 150.w,
                            height: 50.h,
                            decoration: ShapeDecoration(
                              color: Color(0xFF9B9ECF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '내 정보 수정',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontFamily: 'Jua',
                                  fontWeight: FontWeight.w400,
                                  height: 1.h,
                                  letterSpacing: -0.23.w,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 25.w),
                    child: Container(
                      height: 1.h,
                      color: Color(0xffd9d9d9),
                    ),
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  CategoryText(text: '감상 중인 작품'),
                  SizedBox(
                    height: 5.h,
                  ),
                  // 감상 중인 작품 리스트
                  SizedBox(
                    height: 180.h,
                    child: Obx(() {
                      if (controller.readingBooks.isEmpty) {
                        return Center(child: Text("감상 중인 작품이 없습니다."));
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.readingBooks.length,
                        itemBuilder: (context, index) {
                          final book = controller.readingBooks[index];
                          return Padding(
                            padding: EdgeInsets.only(
                                top: 10.h, bottom: 10.h, right: 10.w),
                            child: CustomCard(
                              title: book.title!,
                              tags: book.tags!, // 태그 데이터 삽입
                              onTap: () {
                                controller.toIntroPage(book.title!);
                              },
                              coverImage: book.coverImage!, // 표지 이미지
                            ),
                          );
                        },
                      );
                    }),
                  ),

                  SizedBox(height: 20.h),
                  CategoryText(text: '감상한 작품'),
                  SizedBox(height: 5.h),
// 감상한 작품 리스트
                  SizedBox(
                    height: 180.h,
                    child: Obx(() {
                      if (controller.finishedBooks.isEmpty) {
                        return Center(child: Text("감상한 작품이 없습니다."));
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.finishedBooks.length,
                        itemBuilder: (context, index) {
                          final book = controller.finishedBooks[index];
                          return Padding(
                            padding: EdgeInsets.only(
                                top: 10.h, bottom: 10.h, right: 10.w),
                            child: CustomCard(
                              title: book.title!,
                              tags: book.tags!, // 태그 데이터 삽입
                              onTap: () {
                                controller.toIntroPage(book.title!);
                              },
                              coverImage: book.coverImage!, // 표지 이미지
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  SizedBox(
                    height: 20.h,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(
                        width: 5.w,
                      ),
                      CategoryText(text: '메시지 충전'),
                    ],
                  ),
                  SizedBox(
                    height: 15.h,
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 25.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 남은 메시지 개수
                        Container(
                          width: 150.w,
                          height: 35.h,
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  width: 1.w, color: AppTheme.primaryColor),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Center(
                            child: // 남은 메시지 개수
                                Obx(() => Text(
                                      '남은 메시지: ${controller.messageCount.value}개',
                                      style: TextStyle(
                                        color: Color(0xFF9B9ECF),
                                        fontSize: 16.sp,
                                        fontFamily: 'Jua',
                                        fontWeight: FontWeight.w400,
                                        height: 1.25.h,
                                        letterSpacing: -0.23.w,
                                      ),
                                    )),
                          ),
                        ),
                        SizedBox(
                          width: 10.w,
                        ),
                        // 충전하러 가기 버튼
                        GestureDetector(
                          onTap: () {
                            _showChargeBottomSheet(context, controller);
                          }, // 충전 화면으로
                          child: Container(
                            width: 150.w,
                            height: 35.h,
                            decoration: ShapeDecoration(
                              color: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '충전하러 가기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontFamily: 'Jua',
                                  fontWeight: FontWeight.w400,
                                  height: 1.25.h,
                                  letterSpacing: -0.23.w,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 50.h,
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 25.w, bottom: 30.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 로그아웃 버튼
                        GestureDetector(
                          onTap: () async {
                            await ApiService().deleteToken(); //토큰 삭제
                            Get.offAllNamed('/sign_up');
                          },
                          child: Text(
                            '로그아웃',
                            style: TextStyle(
                              color: Color(0xFF7C7C7C),
                              fontSize: 14.sp,
                              fontFamily: 'Jua',
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline,
                              height: 1.43.h,
                              letterSpacing: -0.23.w,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50.h,
                        ),
                        Container(
                          width: 1.w,
                          height: 20.h,
                          color: Color(0xffd9d9d9),
                        ),
                        SizedBox(
                          width: 50.h,
                        ),
                        // 회원 탈퇴 버튼
                        GestureDetector(
                          onTap: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return CustomAlertDialog(
                                    question: '정말 StoryMate에서\n탈퇴하시겠어요? 😢');
                              },
                            );
                            if (result == true) {
                              // await ApiService().deleteToken();
                              await controller.deleteUserAccount();
                              // '예' 클릭 시
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: AppTheme.backgroundColor,
                                    content: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Text(
                                        '탈퇴 처리되었습니다.\n다음에 또 만나요 👋',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 25.sp,
                                          fontFamily: 'Jua',
                                          fontWeight: FontWeight.w400,
                                          height: 1.40.h,
                                          letterSpacing: -0.23.w,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );

                              // 3초 뒤에 앱 종료료
                              await Future.delayed(Duration(seconds: 3));
                              SystemNavigator.pop();
                            } else {
                              // '아니오' 클릭 시
                              // 아무 동작도 하지 않고 다이얼로그를 닫음
                            }
                          },
                          child: Text(
                            '회원 탈퇴',
                            style: TextStyle(
                              color: Color(0xFF7C7C7C),
                              fontSize: 14.sp,
                              fontFamily: 'Jua',
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline,
                              height: 1.43.h,
                              letterSpacing: -0.23.w,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 메시지 충전 모달창
void _showChargeBottomSheet(BuildContext context, MyController controller) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 바
            Center(
              child: Container(
                width: 50.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 30.h),
            Text(
              '메시지 충전 단위를 선택해 주세요',
              style: TextStyle(
                color: Colors.black,
                fontSize: 25.sp,
                fontFamily: 'Jua',
                fontWeight: FontWeight.w400,
                height: 0.80,
                letterSpacing: -0.23,
              ),
            ),
            SizedBox(height: 15.h),
            // 현재 메시지 갯수
            Text(
              '현재 내 보유 메시지 갯수: ${controller.messageCount.value}개',
              style: TextStyle(
                color: Color(0xFF7C7C7C),
                fontSize: 18.sp,
                fontFamily: 'Jua',
                fontWeight: FontWeight.w400,
                height: 1.11,
                letterSpacing: -0.23,
              ),
            ),
            // 충전 옵션 리스트
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 30.h),
              child: Column(
                children: [
                  _buildChargeOption(context, 30, 500, 1), // ProductId 1
                  SizedBox(height: 10.h),
                  _buildChargeOption(context, 70, 1000, 2), // ProductId 2
                ],
              ),
            )
          ],
        ),
      );
    },
  );
}

Widget _buildChargeOption(
    BuildContext context, int amount, int price, int productId) {
  return GestureDetector(
    onTap: () {
      Navigator.pop(context); // 모달 닫기
      _requestPayment(productId); // 결제 요청 (상품 ID 전달)
    },
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 15.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '메시지 ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22.sp,
                    fontFamily: 'Jua',
                    fontWeight: FontWeight.w400,
                    height: 0.91,
                    letterSpacing: -0.23,
                  ),
                ),
                TextSpan(
                  text: '$amount',
                  style: TextStyle(
                    color: Color(0xFF9B9ECF),
                    fontSize: 22.sp,
                    fontFamily: 'Jua',
                    fontWeight: FontWeight.w400,
                    height: 0.91,
                    letterSpacing: -0.23,
                  ),
                ),
                TextSpan(
                  text: '개',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22.sp,
                    fontFamily: 'Jua',
                    fontWeight: FontWeight.w400,
                    height: 0.91,
                    letterSpacing: -0.23,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 100.w,
            height: 40.h,
            decoration: ShapeDecoration(
              color: Color(0xFF9B9ECF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Center(
              child: Text(
                '$price원',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontFamily: 'Jua',
                  fontWeight: FontWeight.w400,
                  height: 1.11,
                  letterSpacing: -0.23,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _requestPayment(int productId) {
  Get.toNamed('/my_page/payments', arguments: {"productId": productId});
}

class CategoryText extends StatelessWidget {
  final String text;

  const CategoryText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.primaryColor,
        fontSize: 20,
        fontFamily: 'Jua',
        fontWeight: FontWeight.w400,
        height: 1,
        letterSpacing: -0.23,
      ),
    );
  }
}
