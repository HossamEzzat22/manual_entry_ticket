import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import 'gaps.dart';

class SuccessDialog {
  static void show(BuildContext context, {required String ticketNo, required String plateNo}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.w)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28.sp),
            Gaps.w8,
            Text(
              "Ticket Created",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.darkBlue),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ticket generated successfully.", style: TextStyle(fontSize: 12.sp, color: Colors.black87)),
            Gaps.h16,
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.w),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    "TICKET NUMBER",
                    style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w500, color: AppColors.subtitleText),
                  ),
                  Text(
                    ticketNo,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.darkBlue, letterSpacing: 1.1),
                  ),
                  const Divider(height: 16, color: Colors.black12),
                  Text(
                    "VEHICLE PLATE",
                    style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w500, color: AppColors.subtitleText),
                  ),
                  Text(
                    plateNo,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              "OK",
              style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }
}
