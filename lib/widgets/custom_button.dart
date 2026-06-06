import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;
  final Color? color; // ← new: overrides background (outlined → fill) or fill color

  const CustomButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
    this.color,       // ← new
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // When a custom color is supplied the button is always rendered as an
    // ElevatedButton so the color is visible, regardless of isPrimary.
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