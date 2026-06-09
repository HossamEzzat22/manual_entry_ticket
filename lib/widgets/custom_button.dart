import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDisabled; // ← new: shows grey style and blocks taps
  final IconData? icon;
  final Color? color;

  const CustomButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.isDisabled = false, // ← new
    this.icon,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    // ── Disabled state — always grey, taps blocked ────────────────────────
    if (isDisabled) {
      final style = ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade300,
        foregroundColor: Colors.grey.shade500,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.w),
        ),
      );
      final textWidget = Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      );
      if (icon != null) {
        return ElevatedButton.icon(
          onPressed: null, // truly disabled — no tap at all
          icon: Icon(icon, size: 20.sp),
          label: textWidget,
          style: style,
        );
      }
      return ElevatedButton(
        onPressed: null,
        style: style,
        child: textWidget,
      );
    }

    // ── Custom color ──────────────────────────────────────────────────────
    if (color != null) {
      final style = ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.w),
        ),
      );
      final textWidget = Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      );
      if (icon != null) {
        return ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20.sp),
          label: textWidget,
          style: style,
        );
      }
      return ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: textWidget,
      );
    }

    // ── Original logic (unchanged) ────────────────────────────────────────
    final style = isPrimary
        ? ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.darkBlue,
      elevation: 2,
      padding: EdgeInsets.symmetric(vertical: 14.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.w),
      ),
    )
        : OutlinedButton.styleFrom(
      foregroundColor: AppColors.darkBlue,
      side: const BorderSide(color: AppColors.darkBlue),
      padding: EdgeInsets.symmetric(vertical: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.w),
      ),
    );

    final textWidget = Text(
      label,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );

    if (isPrimary) {
      if (icon != null) {
        return ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20.sp),
          label: textWidget,
          style: style,
        );
      }
      return ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: textWidget,
      );
    } else {
      if (icon != null) {
        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20.sp),
          label: textWidget,
          style: style,
        );
      }
      return OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: textWidget,
      );
    }
  }
}