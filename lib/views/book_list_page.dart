import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:storymate/components/custom_app_bar.dart';
import 'package:storymate/components/custom_card.dart';
import 'package:storymate/components/theme.dart';

class BookListPage extends StatelessWidget {
  const BookListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 카테고리 정보 받기
    final String category = Get.arguments ?? 'Unknown Category';

    // 샘플 데이터
    final List<Map<String, String>> items = List.generate(
      10,
      (index) => {
        "title": "작품 제목 ${index + 1}",
        "tags": "#Tag${index + 1} #Example",
      },
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: CustomAppBar(
        leading: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
        ),
        title: category,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600
                ? 3
                : 2, // 화면 크기에 따라 열 개수 변경
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
            childAspectRatio: 3 / 4,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomCard(
                title: item['title']!,
                tags: item['tags']!,
              ),
            );
          },
        ),
      ),
    );
  }
}
