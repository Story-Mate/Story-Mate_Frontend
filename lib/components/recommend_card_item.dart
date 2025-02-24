import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:storymate/components/custom_card.dart';
import 'package:storymate/components/theme.dart';
import 'package:storymate/models/book.dart';
import 'package:storymate/view_models/home_controller.dart';
import 'package:storymate/views/read/book_intro_page.dart';

class RecommendCardItem extends StatefulWidget {
  final Book book; // Book 모델 사용
  final bool isCharacter;
  final int? characterId; // 캐릭터 ID

  const RecommendCardItem({
    super.key,
    required this.book,
    required this.isCharacter,
    this.characterId,
  });

  @override
  State<RecommendCardItem> createState() => _RecommendCardItemState();
}

class _RecommendCardItemState extends State<RecommendCardItem> {
  final HomeController controller =
      Get.find<HomeController>(); // HomeController 인스턴스 가져오기

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350.w,
      height: 181.h,
      decoration: ShapeDecoration(
        color: Color(0xFFF2F2F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // 책 커버 이미지 추가
            CustomCard(
              title: widget.book.title!,
              tags: widget.book.tags!,
              onTap: () {
                Get.to(BookIntroPage(), arguments: widget.book.title);
              },
              coverImage: widget.book.coverImage!, // 실제 이미지 경로 적용
            ),
            Padding(
              padding: EdgeInsets.only(top: 10.h, left: 10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 제목 표시 (작품 설명 또는 주요 캐릭터)
                  Padding(
                    padding: EdgeInsets.only(right: 100.w),
                    child: Text(
                      widget.isCharacter ? '주요 캐릭터' : '작품 설명',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.sp,
                        fontFamily: 'Jua',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  // 작품 설명 or 주요 캐릭터
                  Container(
                    width: 190.w,
                    height: 77.h,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: widget.isCharacter
                          ? Row(
                              children: [
                                // 캐릭터 사진 (원형)
                                ClipOval(
                                  child: Image.asset(
                                    widget.book.characterImage!,
                                    width: 60.w,
                                    height: 60.h,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // 캐릭터명 및 소개
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.w),
                                  child: Text(
                                    widget.book.characterName!,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15.sp,
                                      fontFamily: 'Jua',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Text(
                                widget.book.description!.length > 50
                                    ? "${widget.book.description!.substring(0, 50)}..."
                                    : widget.book.description!, // 작품 설명 적용
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF303030),
                                  fontSize: 11.sp,
                                  fontFamily: 'Jua',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // 감상 / 대화하기 버튼
                  Padding(
                    padding: EdgeInsets.only(left: 10.w),
                    child: GestureDetector(
                      onTap: () async {
                        if (widget.isCharacter) {
                          if (widget.characterId != 0) {
                            bool isChatRoomCreated =
                                await controller.createChatRoom(
                              widget.book.characterName!,
                              widget.characterId!,
                              widget.book.title!,
                            );

                            if (!isChatRoomCreated) {
                              // 채팅방 생성 실패 시 안내창 띄우기
                              Get.snackbar(
                                "알림",
                                "아직 대화 기능이 개설되지 않은 캐릭터입니다.",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.redAccent,
                                colorText: Colors.white,
                              );
                            }
                          } else {
                            Get.snackbar(
                              "알림",
                              "아직 대화 기능이 개설되지 않은 캐릭터입니다.",
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.redAccent,
                              colorText: Colors.white,
                            );
                          }
                        } else {
                          Get.to(BookIntroPage(), arguments: {
                            'title': widget.book.title,
                          });
                        }
                      },
                      child: Container(
                        width: 161.80.w,
                        height: 37.h,
                        decoration: ShapeDecoration(
                          color: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          shadows: [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 3,
                              offset: Offset(0, 3),
                              spreadRadius: 0,
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.isCharacter
                                ? '${widget.book.characterName}와(과) 대화하기'
                                : '${widget.book.title} 감상하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontFamily: 'Jua',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
