import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:storymate/components/theme.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        unselectedLabelStyle: TextStyle(
          color: Color(0xFF7C7C7C),
          fontSize: 12,
          fontFamily: 'Jua',
          fontWeight: FontWeight.w400,
          height: 1.67,
          letterSpacing: -0.23,
        ),
        selectedLabelStyle: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 12,
          fontFamily: 'Jua',
          fontWeight: FontWeight.w400,
          height: 1.67,
          letterSpacing: -0.23,
        ),
        selectedItemColor: AppTheme.primaryColor,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/chat.svg'),
            label: '대화하기',
            activeIcon: SvgPicture.asset('assets/chat_selected.svg'),
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/home.svg'),
            label: '홈',
            activeIcon: SvgPicture.asset('assets/home_selected.svg'),
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/user.svg'),
            label: '마이페이지',
            activeIcon: SvgPicture.asset('assets/user_selected.svg'),
          ),
        ],
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              // 대화하기 탭
              break;
            case 1:
              // 홈 탭
              Get.toNamed('/');
              break;
            default:
              // 마이페이지 탭
              break;
          }
        },
      ),
    );
  }
}
