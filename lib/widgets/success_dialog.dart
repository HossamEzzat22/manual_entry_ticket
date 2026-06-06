import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';

class SuccessDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SuccessDialogContent(),
    );

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) Navigator.of(context).pop();
    });
  }
}

class _SuccessDialogContent extends StatefulWidget {
  const _SuccessDialogContent();

  @override
  State<_SuccessDialogContent> createState() => _SuccessDialogContentState();
}

class _SuccessDialogContentState extends State<_SuccessDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _barController;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Green circle with checkmark
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: const Color(0xFF2E7D32),
                size: 32.sp,
              ),
            ),
            SizedBox(height: 16.h),

            // Title
            Text(
              "Ticket inserted successfully",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlue,
              ),
            ),
            SizedBox(height: 4.h),

            // Subtitle
            Text(
              "Closing automatically…",
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black45,
              ),
            ),
            SizedBox(height: 16.h),

            // Countdown progress bar (drains left to right)
            AnimatedBuilder(
              animation: _barController,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: 1.0 - _barController.value, // drains
                    minHeight: 4.h,
                    backgroundColor: Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF0F6E56), // AppColors.primary teal
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}