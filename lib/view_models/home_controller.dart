import 'package:get/get.dart';

class HomeController extends GetxController {
  // 선택된 카테고리 정보
  final RxString selectedCategory = ''.obs;

  // 카테고리 선택 메서드
  void setCategory(String category) {
    selectedCategory.value = category;
    Get.toNamed('/book_list', arguments: category);
  }
}
