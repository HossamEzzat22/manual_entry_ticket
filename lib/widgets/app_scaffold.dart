
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import 'gaps.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.body, super.key});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Image.asset(
                    AppAssets.logo,
                    height: 48.h,
                    errorBuilder: (_, __, ___) => Container(
                      height: 48.h,
                      width: 48.h,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.local_parking, size: 24.sp),
                    ),
                  ),
                  Gaps.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            AppStrings.appNameAr,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBlue,
                            ),
                          ),
                        ),
                        Text(
                          AppStrings.appNameEn,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E2E2)),
            Expanded(child: body),
            // Container(
            //   height: 56.h,
            //   color: AppColors.bottomBar,
            //   padding: EdgeInsets.symmetric(horizontal: 16.w),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Row(
            //         children: [
            //           Container(
            //             width: 26.w,
            //             height: 26.h,
            //             decoration: const BoxDecoration(
            //               color: AppColors.primary,
            //               shape: BoxShape.circle,
            //             ),
            //             child: Center(
            //               child: Image.asset(
            //                 AppAssets.parkAssistLogo,
            //                 width: 16.w,
            //                 height: 16.h,
            //                 color: Colors.black,
            //                 errorBuilder: (_, __, ___) =>
            //                     Icon(Icons.visibility, size: 15.sp),
            //               ),
            //             ),
            //           ),
            //           Gaps.w8,
            //           Column(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Text(
            //                 AppStrings.parkAssist,
            //                 style: TextStyle(
            //                   color: Colors.white,
            //                   fontWeight: FontWeight.bold,
            //                   fontSize: 11.sp,
            //                 ),
            //               ),
            //               Text(
            //                 AppStrings.parkAssistTagline,
            //                 style: TextStyle(
            //                   color: Colors.white,
            //                   fontSize: 8.sp,
            //                   letterSpacing: 1.1,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ],
            //       ),
            //       Container(
            //         width: 30.w,
            //         height: 30.h,
            //         decoration: const BoxDecoration(
            //           color: AppColors.darkBlue,
            //           shape: BoxShape.circle,
            //         ),
            //         child: Center(
            //           child: Image.asset(
            //             AppAssets.accessibilityIcon,
            //             width: 16.w,
            //             height: 16.h,
            //             color: Colors.white,
            //             errorBuilder: (_, __, ___) =>
            //                 Icon(Icons.accessible, color: Colors.white, size: 16.sp),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
