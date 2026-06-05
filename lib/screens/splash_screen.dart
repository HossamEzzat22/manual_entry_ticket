import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../cubits/splash/splash_cubit.dart';
import '../widgets/gaps.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger the 2-second delay on launch
    context.read<SplashCubit>().startSplashDelay();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is SplashLoaded) {
          Navigator.pushReplacementNamed(context, '/login_screen');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBlue,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Beautiful branded emblem with airport style
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.local_parking_rounded,
                    size: 56.sp,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
              Gaps.h32,
              Text(
                AppStrings.appNameEn,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Gaps.h8,
              Text(
                AppStrings.appNameAr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gaps.h4,
              Text(
                AppStrings.parkAssistTagline,
                style: TextStyle(
                  color: AppColors.subtitleText,
                  fontSize: 10.sp,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 80),
              // Premium modern loading animation
              SpinKitDoubleBounce(
                color: AppColors.primary,
                size: 40.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
