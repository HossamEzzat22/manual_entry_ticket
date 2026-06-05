import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class DioHelper {
  static Dio? dio;

  static init() {
    dio = Dio(BaseOptions(
      //  (Android emulator)
      // baseUrl: 'https://10.0.2.2:7173/',

// (real device on same Wi-Fi)
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

  static Future<Response> getData({
    required String url,
    Map<String, dynamic>? query,
    String? token,
  }) async {
    dio?.options.headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    return await dio!.get(url, queryParameters: query);
  }

  static Future<Response> postData({
    required String url,
    Map<String, dynamic>? query,
    required dynamic data,
    String? token,
  }) {
    dio?.options.headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    return dio!.post(url, queryParameters: query, data: data);
  }

  static Future<Response> putData({
    required String url,
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    dio!.options.headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    return await dio!.put(url, queryParameters: query, data: data);
  }

  static Future<Response> deleteData({
    required String url,
    String? token,
  }) async {
    dio!.options.headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    return await dio!.delete(url);
  }
}