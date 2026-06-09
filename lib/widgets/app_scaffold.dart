import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import 'gaps.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.body, super.key});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [

              // ── Header ───────────────────────────────────────────────────
              Container(
                color: AppColors.darkBlue,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    SvgPicture.asset(
                      AppAssets.logo,
                      height: 44.h,
                    ),

                    SizedBox(width: 180.w), // ⬅️ المسافة اللي انت عايزها

                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'PARKING',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: AppColors.primary,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Thin copper accent line
              Container(height: 2.h, color: AppColors.primary),

              // ── Body ─────────────────────────────────────────────────────
              Expanded(child: body),

              // ── Footer ───────────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: AppColors.darkBlue,
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${AppStrings.poweredBy} ',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.white30,
                      ),
                    ),
                    Image.asset(
                      AppAssets.unifiAccessLogo,
                      height: 16.h,
                    ),
                    Gaps.w4,
                    Text(
                      AppStrings.unifiAccess,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}