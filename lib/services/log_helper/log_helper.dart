import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class LogHelper {
  static const int _maxAgeDays = 30;
  static const String _logsFolderName = 'logs';

  // Cached directory path — resolved once, reused for every write
  static String? _logsDirPath;

  // ── Internal helpers ────────────────────────────────────────────────────────

  static Future<String> _getLogsDirPath() async {
    if (_logsDirPath != null) return _logsDirPath!;
    final appDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${appDir.path}/$_logsFolderName');
    if (!logsDir.existsSync()) {
      logsDir.createSync(recursive: true);
    }
    _logsDirPath = logsDir.path;
    if (kDebugMode) print('[LogHelper] logs directory: $_logsDirPath');
    return _logsDirPath!;
  }

  static Future<File> _getTodayFile() async {
    final dirPath = await _getLogsDirPath();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final file = File('$dirPath/logs_$today.txt');
    // Create file if it doesn't exist yet so it shows up in directory listing
    if (!file.existsSync()) {
      file.createSync();
      if (kDebugMode) print('[LogHelper] Created new log file: ${file.path}');
    }
    return file;
  }

  static String _timestamp() =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  static Future<void> _writeLine(String line) async {
    try {
      final file = await _getTodayFile();
      file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
      if (kDebugMode) print('[LogHelper] wrote: $line');
    } catch (e) {
      if (kDebugMode) print('[LogHelper] WRITE ERROR: $e');
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Log a general action.
  /// [tag]     — category in uppercase, e.g. 'CAMERA', 'API', 'SETTINGS'
  /// [message] — human-readable description
  static Future<void> log(String tag, String message) async {
    final line = '[${_timestamp()}] [$tag] $message';
    await _writeLine(line);
  }

  /// Log an exception with its stack trace.
  static Future<void> logException(
      String context,
      Object error,
      StackTrace stackTrace,
      ) async {
    final line = '[${_timestamp()}] [ERROR] $context\n'
        '  Exception: $error\n'
        '  StackTrace: ${stackTrace.toString().split('\n').take(5).join(' | ')}';
    await _writeLine(line);
  }

  /// Log an outgoing API request.
  /// Base64 strings in [data] are truncated automatically.
  static Future<void> logApiRequest(
      String method,
      String endpoint, {
        Map<String, dynamic>? data,
      }) async {
    String dataStr = '';
    if (data != null) {
      final sanitized = data.map((k, v) {
        if (v is String && v.length > 200) {
          return MapEntry(k, '[truncated, length: ${v.length}]');
        }
        return MapEntry(k, v);
      });
      dataStr = ' | data: $sanitized';
    }
    final line = '[${_timestamp()}] [API] $method $endpoint$dataStr';
    await _writeLine(line);
  }

  /// Returns all log files sorted newest → oldest.
  static Future<List<File>> getAllLogFiles() async {
    try {
      final dirPath = await _getLogsDirPath();
      final logsDir = Directory(dirPath);

      if (!logsDir.existsSync()) {
        if (kDebugMode) print('[LogHelper] getAllLogFiles: directory does not exist');
        return [];
      }

      final files = logsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.txt'))
          .toList();

      if (kDebugMode) print('[LogHelper] getAllLogFiles: found ${files.length} files');
      for (final f in files) {
        if (kDebugMode) print('[LogHelper]   → ${f.path} (${f.lengthSync()} bytes)');
      }

      files.sort((a, b) => b.path.compareTo(a.path)); // newest first
      return files;
    } catch (e) {
      if (kDebugMode) print('[LogHelper] getAllLogFiles ERROR: $e');
      return [];
    }
  }

  /// Deletes log files older than [_maxAgeDays] days.
  /// Called from SplashCubit on app startup.
  static Future<void> deleteOldLogs() async {
    try {
      final dirPath = await _getLogsDirPath();
      final logsDir = Directory(dirPath);
      if (!logsDir.existsSync()) return;

      final cutoff = DateTime.now().subtract(const Duration(days: _maxAgeDays));
      final files = logsDir.listSync().whereType<File>();

      for (final file in files) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoff)) {
          await file.delete();
          if (kDebugMode) print('[LogHelper] Deleted old log: ${file.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('[LogHelper] deleteOldLogs ERROR: $e');
    }
  }
}