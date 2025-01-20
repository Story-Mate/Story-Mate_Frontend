import 'package:flutter/material.dart';
import 'package:storymate/components/custom_card.dart';
import 'package:storymate/components/theme.dart';

class RecommendCardItem extends StatelessWidget {
  final String title;
  final String tag;
  final String character;
  final String characterIntro;

  const RecommendCardItem({
    super.key,
    required this.title,
    required this.tag,
    required this.character,
    required this.characterIntro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 347,
      height: 181,
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
            CustomCard(title: title, tags: tag),
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 100),
                    child: Text(
                      '주요 캐릭터',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: 'Jua',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  // 주요 캐릭터 소개
                  Container(
                    width: 191,
                    height: 77,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // 캐릭터 사진
                          Container(
                            width: 60,
                            height: 60,
                            decoration: ShapeDecoration(
                              color: Color(0xFFD9D9D9),
                              shape: OvalBorder(
                                side: BorderSide(width: 0.30),
                              ),
                            ),
                          ),
                          // 캐릭터명
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  character,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontFamily: 'Jua',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                // 한 줄 소개
                                Text(
                                  characterIntro,
                                  style: TextStyle(
                                    color: Color(0xFF303030),
                                    fontSize: 11,
                                    fontFamily: 'Jua',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 대화하기 버튼
                  Container(
                    width: 161.80,
                    height: 37,
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
                        '$character와(과) 대화하러 가기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'Jua',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
