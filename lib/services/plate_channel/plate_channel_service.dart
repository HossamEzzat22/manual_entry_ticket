import 'package:flutter/services.dart';


class PlateChannelService {
  static const MethodChannel _channel = MethodChannel('com.yourapp/plate_detection');


  static Future<String?> detectAndCropPlate(String base64Image) async {
    try {
      final String? croppedBase64 = await _channel.invokeMethod<String>(
        'detectAndCropPlate',
        {'base64Image': base64Image},
      );
      // null means the detector ran but found no plate — not an error
      return croppedBase64;
    } on PlatformException catch (e) {
      throw PlateDetectionException(
        code: e.code,
        message: e.message ?? 'Unknown native error',
      );
    }
  }
}

/// Thrown when the native plate detection channel returns an error.
class PlateDetectionException implements Exception {
  final String code;
  final String message;

  const PlateDetectionException({required this.code, required this.message});

  @override
  String toString() => 'PlateDetectionException[$code]: $message';
}