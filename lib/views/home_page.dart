import 'package:flutter/material.dart';
import 'package:storymate/components/custom_app_bar.dart';
import 'package:storymate/components/custom_bottom_bar.dart';
import 'package:storymate/components/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                      onTap: () {},
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
                      onTap: () {},
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
                      onTap: () {},
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
                      onTap: () {},
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

class CustomCard extends StatelessWidget {
  final String title;
  final String tags;

  const CustomCard({
    super.key,
    required this.title,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 129,
      decoration: BoxDecoration(
        color: Color(0xffd9d9d9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.6),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Jua',
                fontWeight: FontWeight.w400,
                height: 1.33,
                letterSpacing: -0.23,
              ),
            ),
            Text(
              tags,
              style: TextStyle(
                color: Color(0xFF7C7C7C),
                fontSize: 10,
                fontFamily: 'Jua',
                fontWeight: FontWeight.w400,
                height: 2,
                letterSpacing: -0.23,
              ),
            ),
          ],
        ),
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
