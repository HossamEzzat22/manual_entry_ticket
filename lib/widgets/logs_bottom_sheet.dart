import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:manual_entry_ticket/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../services/log_helper/log_helper.dart';

class LogsBottomSheet extends StatefulWidget {
  const LogsBottomSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LogsBottomSheet._(),
    );
  }

  @override
  State<LogsBottomSheet> createState() => _LogsBottomSheetState();
}

class _LogsBottomSheetState extends State<LogsBottomSheet> {
  List<File> _logFiles = [];
  bool _isLoading = true;
  String? _sharingFilePath;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final files = await LogHelper.getAllLogFiles();
    if (mounted) {
      setState(() {
        _logFiles = files;
        _isLoading = false;
      });
    }
  }

  Future<void> _shareFile(File file) async {
    if (_sharingFilePath != null) return;
    setState(() => _sharingFilePath = file.path);
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'App Logs — ${_formatFileName(file)}',
      );
      await LogHelper.log('SHARE', 'Log file shared: ${file.path}');
    } catch (e, st) {
      await LogHelper.logException('Failed to share log file', e, st);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToShare(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharingFilePath = null);
    }
  }

  String _formatFileName(File file) {
    try {
      final name = file.uri.pathSegments.last;
      final datePart = name.replaceAll('logs_', '').replaceAll('.txt', '');
      final date = DateFormat('yyyy-MM-dd').parse(datePart);
      final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == datePart;
      if (isToday) return 'Today — ${DateFormat('EEE, MMM d yyyy').format(date)}';
      return DateFormat('EEE, MMM d yyyy').format(date);
    } catch (_) {
      return file.uri.pathSegments.last;
    }
  }

  String _formatFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }

  bool _isToday(File file) {
    try {
      final name = file.uri.pathSegments.last;
      final datePart = name.replaceAll('logs_', '').replaceAll('.txt', '');
      return DateFormat('yyyy-MM-dd').format(DateTime.now()) == datePart;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined, size: 20.sp, color: Colors.grey[700]),
                    SizedBox(width: 8.w),
                    Text(
                      l10n.logFiles,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[850],
                      ),
                    ),
                    const Spacer(),
                    if (!_isLoading)
                      Text(
                        '${_logFiles.length} file${_logFiles.length == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              Divider(height: 20.h, color: const Color(0xFFE2E2E2)),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _logFiles.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 48.sp, color: Colors.grey[300]),
                      SizedBox(height: 12.h),
                      Text(
                        l10n.noLogFilesFound,
                        style: TextStyle(fontSize: 13.sp, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  itemCount: _logFiles.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: const Color(0xFFE2E2E2),
                    indent: 56.w,
                  ),
                  itemBuilder: (_, index) {
                    final file = _logFiles[index];
                    final isSharing = _sharingFilePath == file.path;
                    final today = _isToday(file);

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 4.h,
                      ),
                      leading: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: today
                              ? const Color(0xFFE8F4FD)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          today
                              ? Icons.today_outlined
                              : Icons.insert_drive_file_outlined,
                          size: 20.sp,
                          color: today
                              ? const Color(0xFF1A73E8)
                              : Colors.grey[500],
                        ),
                      ),
                      title: Text(
                        _formatFileName(file),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: today ? FontWeight.w600 : FontWeight.w400,
                          color: Colors.grey[850],
                        ),
                      ),
                      subtitle: Text(
                        _formatFileSize(file),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                      trailing: isSharing
                          ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey[600],
                        ),
                      )
                          : Icon(
                        Icons.share_outlined,
                        size: 20.sp,
                        color: Colors.grey[600],
                      ),
                      onTap: isSharing ? null : () => _shareFile(file),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}