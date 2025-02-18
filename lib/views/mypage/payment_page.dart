// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:storymate/components/theme.dart';
// import 'package:storymate/view_models/mypage/payment_controller.dart';
// import 'package:tosspayments_widget_sdk_flutter/widgets/agreement.dart';
// import 'package:tosspayments_widget_sdk_flutter/widgets/payment_method.dart';

// class PaymentPage extends StatelessWidget {
//   const PaymentPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final PaymentController controller = Get.put(PaymentController());

//     return Scaffold(
//       backgroundColor: AppTheme.backgroundColor,
//       appBar: AppBar(
//         forceMaterialTransparency: true,
//         automaticallyImplyLeading: false,
//         title: const Text(
//           '메시지 충전',
//           style: TextStyle(
//             fontFamily: 'Jua',
//           ),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new),
//           onPressed: () => Get.back(),
//         ),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView(
//                 padding: const EdgeInsets.all(16),
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 15.w),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           '충전 금액',
//                           style: TextStyle(
//                             fontSize: 20.sp,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           '${controller.amount}원',
//                           style: TextStyle(
//                             fontSize: 18.sp,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Padding(
//                     padding: EdgeInsets.only(top: 10.h),
//                     child: Divider(
//                       color: Color(0xffa2a2a2),
//                     ),
//                   ),
//                   PaymentMethodWidget(
//                     paymentWidget: controller.paymentWidget,
//                     selector: 'methods',
//                   ),
//                   AgreementWidget(
//                       paymentWidget: controller.paymentWidget,
//                       selector: 'agreement'),
//                   const SizedBox(height: 20),
//                   Center(
//                     child: GestureDetector(
//                       onTap: () => controller.requestPayment(),
//                       child: Container(
//                         width: 300.w,
//                         height: 60.h,
//                         decoration: ShapeDecoration(
//                           color: Color(0xFF9B9ECF),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                         child: Center(
//                           child: Text(
//                             '결제하기',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 22.sp,
//                               fontFamily: 'Jua',
//                               fontWeight: FontWeight.w400,
//                               height: 1,
//                               letterSpacing: -0.23,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:storymate/components/theme.dart';
import 'package:storymate/view_models/mypage/payment_controller.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PaymentController controller = Get.put(PaymentController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        title: const Text(
          '메시지 충전',
          style: TextStyle(fontFamily: 'Jua'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '충전 금액',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Obx(() => Text(
                              '${controller.amount}원',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Divider(color: Color(0xffa2a2a2)),
                  ),
                  // 상품 리스트 (In-App Purchase 제품 표시)
                  Obx(
                    () => Column(
                      children: controller.products.map((product) {
                        return ListTile(
                          title: Text(
                            product.title,
                            style: TextStyle(fontSize: 18.sp),
                          ),
                          subtitle: Text(
                            product.description,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          trailing: Text(
                            product.price,
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          onTap: () => controller.purchaseProduct(product),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () => controller.restorePurchases(),
                      child: Container(
                        width: 300.w,
                        height: 60.h,
                        decoration: ShapeDecoration(
                          color: Color(0xFF9B9ECF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '구매 복원',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontFamily: 'Jua',
                              fontWeight: FontWeight.w400,
                              height: 1,
                              letterSpacing: -0.23,
                            ),
                          ),
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
