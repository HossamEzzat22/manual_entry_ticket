import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:intl/intl.dart';

import '../../services/sp_helper/sp_helper.dart';
import '../../services/sp_helper/sp_keys.dart';
import '../../services/log_helper/log_helper.dart';
import '../utils/navigator_key.dart';

class DioHelper {
  static Dio? dio;

  static init() {
    dio = Dio(BaseOptions(
      baseUrl: 'http://192.168.1.10:5169/',
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // Bypass self-signed SSL certificate on local dev server.
    // IMPORTANT: Remove this block before releasing to production.
    (dio!.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  // ── Token resolution ────────────────────────────────────────────────────
  //
  // Priority:
  //   1. If a token is passed explicitly → use it as-is (login call does this)
  //   2. If primary token is still valid → use it
  //   3. If primary token expired but refresh token still valid → use refresh token
  //   4. If both expired → clear session + redirect to login
  //
  static Future<String?> _resolveToken(String? explicitToken) async {
    if (explicitToken != null && explicitToken.isNotEmpty) return explicitToken;

    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final now = DateTime.now();

    final token = SharedPreferenceHelper.getData(
      key: SharedPreferencesKeys.token,
    ) as String? ??
        '';

    final tokenExpiryStr = SharedPreferenceHelper.getData(
      key: SharedPreferencesKeys.tokenExpiryDate,
    ) as String? ??
        '';

    // ── Primary token valid? ─────────────────────────────────────────────
    if (token.isNotEmpty && tokenExpiryStr.isNotEmpty) {
      try {
        final tokenExpiry = fmt.parse(tokenExpiryStr);
        if (now.isBefore(tokenExpiry)) return token;
      } catch (_) {}
    }

    // ── Try refresh token ────────────────────────────────────────────────
    final refreshToken = SharedPreferenceHelper.getData(
      key: SharedPreferencesKeys.refreshToken,
    ) as String? ??
        '';

    final refreshExpiryStr = SharedPreferenceHelper.getData(
      key: SharedPreferencesKeys.refreshTokenExpiryDate,
    ) as String? ??
        '';

    if (refreshToken.isNotEmpty && refreshExpiryStr.isNotEmpty) {
      try {
        final refreshExpiry = fmt.parse(refreshExpiryStr);
        if (now.isBefore(refreshExpiry)) {
          await LogHelper.log(
            'AUTH',
            'DioHelper: primary token expired — using refresh token (valid until $refreshExpiryStr)',
          );
          return refreshToken;
        }
      } catch (_) {}
    }

    // ── Both expired → force logout ──────────────────────────────────────
    await LogHelper.log(
      'AUTH',
      'DioHelper: both token and refresh token expired → clearing session, redirecting to login',
    );
    await _clearSessionAndRedirect();
    return null;
  }

  static Future<void> _clearSessionAndRedirect() async {
    await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.token);
    await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.tokenExpiryDate);
    await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.refreshToken);
    await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.refreshTokenExpiryDate);

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login_screen',
          (route) => false,
    );
  }

  // ── HTTP methods ─────────────────────────────────────────────────────────

  static Future<Response> getData({
    required String url,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    final resolvedToken = await _resolveToken(token);
    dio?.options.headers = {
      'Content-Type': 'application/json',
      if (resolvedToken != null && resolvedToken.isNotEmpty)
        'Authorization': 'Bearer $resolvedToken',
    };
    return await dio!.get(url, queryParameters: query);
  }

  static Future<Response> postData({
    required String url,
    Map<String, dynamic>? query,
    required dynamic data,
    String? token,
  }) async {
    final resolvedToken = await _resolveToken(token);
    dio?.options.headers = {
      'Content-Type': 'application/json',
      if (resolvedToken != null && resolvedToken.isNotEmpty)
        'Authorization': 'Bearer $resolvedToken',
    };
    return await dio!.post(url, queryParameters: query, data: data);
  }

  static Future<Response> putData({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    final resolvedToken = await _resolveToken(token);
    dio!.options.headers = {
      'Content-Type': 'application/json',
      if (resolvedToken != null && resolvedToken.isNotEmpty)
        'Authorization': 'Bearer $resolvedToken',
    };
    return await dio!.put(url, queryParameters: query, data: data);
  }

  static Future<Response> deleteData({
    required String url,
    String? token,
  }) async {
    final resolvedToken = await _resolveToken(token);
    dio!.options.headers = {
      'Content-Type': 'application/json',
      if (resolvedToken != null && resolvedToken.isNotEmpty)
        'Authorization': 'Bearer $resolvedToken',
    };
    return await dio!.delete(url);
  }
}