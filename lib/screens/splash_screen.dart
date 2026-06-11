import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:manual_entry_ticket/l10n/app_localizations.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
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
    final l10n = AppLocalizations.of(context)!;

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
                    SvgPicture.asset(
                      AppAssets.logo,
                      width: 220.w,
                      fit: BoxFit.contain,
                    ),
                    Gaps.h32,
                    Text(
                      l10n.parkAssistTagline,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9.sp,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Gaps.h32,
                    SpinKitDoubleBounce(
                      color: AppColors.primary,
                      size: 36.sp,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 28.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${l10n.poweredBy} ',
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
                    l10n.unifiAccess,
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