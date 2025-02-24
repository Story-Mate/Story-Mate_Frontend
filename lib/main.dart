import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:storymate/view_models/onboarding/login_controller.dart';
import 'package:storymate/view_models/read/book_read_controller.dart';
import 'package:storymate/views/mypage/my_page.dart';
import 'package:storymate/views/onboarding/splash_screen.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  await dotenv.load();
  String kakaoNativeAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);

  // LoginController를 전역 등록 (단, 여기서는 자동 로그인 체크를 하지 않음)
  Get.put(LoginController());

  Get.put(BookReadController(), permanent: true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          // navigatorObservers: [routeObserver],
          debugShowCheckedModeBanner: false,
          title: 'StoryMate',
          initialRoute: '/', // SplashScreen에서 자동 로그인 체크
          getPages: [
            GetPage(name: '/', page: () => SplashScreen()), // 자동 로그인 체크 화면
            ...AppRoutes.routes,
          ],
        );
      },
    );
  }
}
