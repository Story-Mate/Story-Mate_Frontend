import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:storymate/components/custom_app_bar.dart';
import 'package:storymate/components/custom_bottom_bar.dart';
import 'package:storymate/components/custom_card.dart';
import 'package:storymate/components/theme.dart';
import 'package:storymate/view_models/home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());

    // 샘플 데이터
    final List<Map<String, String>> items = [
      {"title": "작품 제목 1", "tags": "#태그1 #태그2"},
      {"title": "작품 제목 2", "tags": "#태그3 #태그4"},
      {"title": "작품 제목 3", "tags": "#태그5 #태그6"},
      {"title": "작품 제목 4", "tags": "#태그7 #태그8"},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CustomAppBar(
        title: 'StoryMate',
        backgroundColor: AppTheme.primaryColor,
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 1,
      ),
      body: ListView(
        children: [
          // 연령대 카드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: SizedBox(
              height: 89,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  AgeCardItem(
                    backgroundColor: AppTheme.childColor,
                    title: '아동',
                    subTitle: '5~12세',
                    tag: '#교훈적인 이야기 #모험과 판타지',
                    tagColor: AppTheme.childAccentColor,
                  ),
                  AgeCardItem(
                    backgroundColor: AppTheme.studentColor,
                    title: '청소년',
                    subTitle: '13~18세',
                    tag: '#세계 명작 #감동적인 이야기',
                    tagColor: AppTheme.studentAccentColor,
                  ),
                  AgeCardItem(
                    backgroundColor: AppTheme.adultColor,
                    title: '성인',
                    subTitle: '19세 이상',
                    tag: '#철학적 메시지 #깊이 있는 스토리',
                    tagColor: AppTheme.adultAccentColor,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 15,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '국내 동화',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'Jua',
                        fontWeight: FontWeight.w400,
                        height: 1.10,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    // 더보기 버튼
                    GestureDetector(
                      onTap: () {
                        controller.setCategory('국내 동화');
                      },
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 15,
                      ),
                    ),
                  ],
                ),
                // 국내 동화 리스트
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                            top: 10, bottom: 10, right: 10),
                        child: CustomCard(
                          title: item["title"] ?? "",
                          tags: item["tags"] ?? "",
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Text(
                      '외국 동화',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'Jua',
                        fontWeight: FontWeight.w400,
                        height: 1.10,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    // 더보기 버튼
                    GestureDetector(
                      onTap: () {
                        controller.setCategory('외국 동화');
                      },
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 15,
                      ),
                    ),
                  ],
                ),
                // 외국 동화 리스트
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                            top: 10, bottom: 10, right: 10),
                        child: CustomCard(
                          title: item["title"] ?? "",
                          tags: item["tags"] ?? "",
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Text(
                      '국내 소설',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'Jua',
                        fontWeight: FontWeight.w400,
                        height: 1.10,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    // 더보기 버튼
                    GestureDetector(
                      onTap: () {
                        controller.selectedCategory('국내 소설');
                      },
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 15,
                      ),
                    ),
                  ],
                ),
                // 국내 소설 리스트
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                            top: 10, bottom: 10, right: 10),
                        child: CustomCard(
                          title: item["title"] ?? "",
                          tags: item["tags"] ?? "",
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Text(
                      '외국 소설',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'Jua',
                        fontWeight: FontWeight.w400,
                        height: 1.10,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    // 더보기 버튼
                    GestureDetector(
                      onTap: () {
                        controller.selectedCategory('외국 소설');
                      },
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 15,
                      ),
                    ),
                  ],
                ),
                // 외국 소설 리스트
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                            top: 10, bottom: 10, right: 10),
                        child: CustomCard(
                          title: item["title"] ?? "",
                          tags: item["tags"] ?? "",
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AgeCardItem extends StatelessWidget {
  final Color backgroundColor;
  final String title;
  final String subTitle;
  final String tag;
  final Color tagColor;

  const AgeCardItem({
    super.key,
    required this.backgroundColor,
    required this.title,
    required this.subTitle,
    required this.tag,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        width: 173,
        height: 89,
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontFamily: 'Jua',
                      fontWeight: FontWeight.w400,
                      height: 0.88,
                    ),
                  ),
                  Text(
                    subTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: 'Jua',
                      fontWeight: FontWeight.w400,
                      height: 1.47,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    tag,
                    style: TextStyle(
                      color: tagColor,
                      fontSize: 10,
                      fontFamily: 'Jua',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
