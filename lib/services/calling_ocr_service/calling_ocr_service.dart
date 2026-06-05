import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result returned by [PlateOcrApiService.recognizePlate].
class PlateOcrResult {
  /// Raw string from the API, e.g. "3407AGD"
  final String raw;

  /// Leading digits extracted from [raw], e.g. "3407"
  final String numbers;

  /// Trailing letters extracted from [raw], e.g. "AGD"
  final String letters;

  const PlateOcrResult({
    required this.raw,
    required this.numbers,
    required this.letters,
  });
}

/// Calls the remote OCR API with a base64-encoded PNG of the cropped plate.
class PlateOcrApiService {
  static const String _endpoint = 'http://qudrapps.com:8321/do_plate_ocr';

  /// Sends the cropped plate image to the OCR API and parses the result.
  ///
  /// [croppedPlateBase64] — base64 PNG of the cropped plate (~94×24 px).
  ///
  /// Returns a [PlateOcrResult] with [raw], [numbers], and [letters].
  ///
  /// Throws a [PlateOcrException] on HTTP errors or unexpected response shapes.
  static Future<PlateOcrResult> recognizePlate(String croppedPlateBase64) async {
    final uri = Uri.parse(_endpoint);

    late http.Response response;
    try {
      response = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pngImageBase64': croppedPlateBase64}),
      )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw PlateOcrException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw PlateOcrException(
        'Server returned ${response.statusCode}: ${response.body}',
      );
    }

    late Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw PlateOcrException('Could not parse response: ${response.body}');
    }

    // API contract: {"success": true, "result": "3407AGD"}
    final success = json['success'] as bool? ?? false;
    if (!success) {
      throw PlateOcrException('API returned success=false: ${response.body}');
    }

    final raw = json['result'] as String? ?? '';
    if (raw.isEmpty) {
      throw PlateOcrException('API returned an empty result string');
    }

    final split = _splitPlateResult(raw);
    return PlateOcrResult(
      raw: raw,
      numbers: split.$1,
      letters: split.$2,
    );
  }

  /// Splits a plate string like "3407AGD" into ("3407", "AGD").
  ///
  /// Strategy: leading digits → numbers, remaining characters → letters.
  /// Handles edge cases where the string is all digits or all letters.
  static (String numbers, String letters) _splitPlateResult(String raw) {
    // Find the index where the first non-digit character appears
    int splitIndex = 0;
    while (splitIndex < raw.length && RegExp(r'\d').hasMatch(raw[splitIndex])) {
      splitIndex++;
    }

    final numbers = raw.substring(0, splitIndex);
    final letters = raw.substring(splitIndex);
    return (numbers, letters);
  }
}

/// Thrown when the OCR API call fails for any reason.
class PlateOcrException implements Exception {
  final String message;
  const PlateOcrException(this.message);

  @override
  String toString() => 'PlateOcrException: $message';
}