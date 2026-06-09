import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_assets.dart';
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
    context.read<SplashCubit>().startSplashDelay();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is SplashLoaded) {
          Navigator.pushReplacementNamed(context, '/login_screen');
        } else if (state is SplashSessionValid) {
          Navigator.pushReplacementNamed(context, '/entry_ticket_screen');
        }
        },
      child: Scaffold(
        backgroundColor: AppColors.darkBlue,
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // ── Logo — no container, raw SVG ─────────────────────
                    SvgPicture.asset(
                      AppAssets.logo,
                      width: 220.w,
                      fit: BoxFit.contain,
                    ),
                    Gaps.h32,

                    // ── Tagline ──────────────────────────────────────────
                    Text(
                      AppStrings.parkAssistTagline,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9.sp,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Gaps.h32,

                    // ── Loading ──────────────────────────────────────────
                    SpinKitDoubleBounce(
                      color: AppColors.primary,
                      size: 36.sp,
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.only(bottom: 28.h),
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
    );
  }
}