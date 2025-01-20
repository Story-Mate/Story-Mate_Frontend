import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:storymate/components/custom_card.dart';
import 'package:storymate/components/recommend_card_item.dart';
import 'package:storymate/components/theme.dart';
import 'package:storymate/view_models/book_search_controller.dart';

class BookSearchPage extends StatelessWidget {
  const BookSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final BookSearchController controller = Get.put(BookSearchController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 66),
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 뒤로 가기 버튼
                  GestureDetector(
                    onTap: () {
                      controller.goBack();
                    },
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xff090A0A),
                    ),
                  ),
                  Container(
                    width: 320,
                    height: 56,
                    decoration: ShapeDecoration(
                      color: Color(0xFF9B9ECF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 작품 검색창
                          SizedBox(
                            width: 200,
                            child: TextField(
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'Jua',
                                fontWeight: FontWeight.w400,
                              ),
                              controller: controller.searchController,
                              decoration: InputDecoration(
                                hintText: '작품 이름으로 검색해 보세요',
                                hintStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontFamily: 'Jua',
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (query) {
                                controller.searchBooks(query); // 검색 호출
                              },
                            ),
                          ),
                          // 검색 버튼
                          GestureDetector(
                            onTap: () {
                              controller.searchBooks(
                                  controller.searchController.text);
                            },
                            child: Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 검색 결과
            Obx(
              () => controller.searchResults.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: controller.searchResults.length,
                        itemBuilder: (context, index) {
                          final result = controller.searchResults[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: CustomCard(
                              title: result['title']!,
                              tags: result['tags']!,
                            ),
                          );
                        },
                      ),
                    )
                  : Expanded(
                      child: ListView(
                        children: [
                          // 추천 작품
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'ㅇㅇ님을 위한 추천 작품',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontFamily: 'Jua',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Center(
                                child: RecommendCardItem(
                                  title: '작품 제목',
                                  tag: '#태그 #3개 #들어감',
                                  character: '캐릭터명',
                                  characterIntro: '한 줄 소개',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          // 추천 작품
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    // 사용자의 연령대
                                    Text(
                                      '20',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 18,
                                        fontFamily: 'Jua',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      '대 ',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontFamily: 'Jua',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    // 사용자의 성별
                                    Text(
                                      '여성',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 18,
                                        fontFamily: 'Jua',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      '에게 인기 많아요',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontFamily: 'Jua',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Center(
                                child: RecommendCardItem(
                                  title: '작품 제목',
                                  tag: '#태그 #3개 #들어감',
                                  character: '캐릭터명',
                                  characterIntro: '한 줄 소개',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
