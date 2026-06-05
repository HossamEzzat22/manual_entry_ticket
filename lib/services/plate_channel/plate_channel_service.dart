import 'package:flutter/services.dart';

/// Result of a native plate-detection call.
///
/// [croppedBase64] is null when the detector ran but found no plate.
/// [diag] is a short human-readable summary from the native detector (model
/// shapes, max confidence, box count) used for troubleshooting; it is written
/// to the app log so issues can be diagnosed from "Share Logs" alone.
class PlateDetectionResult {
  final String? croppedBase64;
  final String? diag;

  const PlateDetectionResult({this.croppedBase64, this.diag});
}

class PlateChannelService {
  static const MethodChannel _channel = MethodChannel('com.yourapp/plate_detection');

  static Future<PlateDetectionResult> detectAndCropPlate(String base64Image) async {
    try {
      final Map<dynamic, dynamic>? raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'detectAndCropPlate',
        {'base64Image': base64Image},
      );

      final map = raw ?? const {};
      return PlateDetectionResult(
        croppedBase64: map['plate'] as String?,
        diag: map['diag'] as String?,
      );
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
