import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manual_entry_ticket/services/log_helper/log_helper.dart';

import '../../services/sp_helper/sp_helper.dart';
import '../../services/sp_helper/sp_keys.dart';

part 'upload_image_file_state.dart';

class UploadImageFileCubit extends Cubit<UploadImageFileState> {
  UploadImageFileCubit() : super(UploadImageFileInitial());

  final ImagePicker _picker = ImagePicker();

  // TODO: Replace with real AI/OCR API endpoints when integrated.
  Future<void> capturePhoto({required bool isAiEnabled}) async {
    emit(UploadImageFilePickLoading());
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo == null) {
        emit(UploadImageFilePickFailure("Camera capture canceled"));
        await LogHelper.log('CAMERA', 'User canceled camera capture');
        return;
      }

      final imagePath = photo.path;
      await LogHelper.log('CAMERA', 'Photo captured successfully: $imagePath');

      // Convert image to base64 in a background isolate to avoid blocking UI
      final base64Image = await compute(_convertImageToBase64, imagePath);

      if (base64Image.isEmpty) {
        emit(UploadImageFilePickFailure("Failed to process captured photo"));
        await LogHelper.log('CAMERA', 'Base64 conversion failed for: $imagePath');
        return;
      }

      // Save base64 string to SharedPreferences
      await SharedPreferenceHelper.saveData(
        key: SharedPreferencesKeys.capturedImagePath,
        value: base64Image,
      );

      await LogHelper.log('CAMERA', 'Photo converted to base64 and saved to SharedPreferences');

      // Show the captured photo immediately using the file path for display
      emit(UploadImageFileCameraSuccess(
        originalImagePath: imagePath,
        base64Image: base64Image,
      ));

      // If AI is disabled, stop here — user will fill plate number manually
      if (!isAiEnabled) {
        await LogHelper.log('CAMERA', 'AI OCR disabled — skipping analysis, manual plate entry mode');
        return;
      }

      // Wait 1 second so user sees their photo, then start OCR
      await Future.delayed(const Duration(seconds: 1));

      // Start OCR — pass both path (for display) and base64 (for API)
      await runMockOcrAnalysis(imagePath, base64Image);
    } catch (e, stackTrace) {
      await LogHelper.logException('Failed to capture photo', e, stackTrace);
      emit(UploadImageFilePickFailure(e.toString()));
    }
  }

  Future<void> runMockOcrAnalysis(String imagePath, String base64Image) async {
    // Pass imagePath so the captured photo box stays visible during OCR loading
    emit(UploadImageFileOcrLoading(imagePath));

    await LogHelper.log('AI_OCR', 'Starting AI OCR analysis on image: $imagePath');

    // Mock processing delay
    await Future.delayed(const Duration(milliseconds: 2500));

    final numbers = _generateRandomSaudiPlateNumbers();
    final letters = _generateRandomSaudiPlateLetters();

    await LogHelper.log('AI_OCR', 'OCR Analysis complete. Result: $numbers $letters');

    emit(UploadImageFileOcrSuccess(
      originalImagePath: imagePath,
      base64Image: base64Image,
      plateImagePath: imagePath, // MOCK: same image used for plate crop preview
      plateNumbers: numbers,
      plateLetters: letters,
    ));
  }

  String _generateRandomSaudiPlateNumbers() {
    final rand = Random();
    final firstDigit = rand.nextInt(9) + 1;
    final extraDigits = rand.nextInt(4);
    String numStr = '$firstDigit';
    for (int i = 0; i < extraDigits; i++) {
      numStr += rand.nextInt(10).toString();
    }
    return numStr;
  }

  String _generateRandomSaudiPlateLetters() {
    const allowed = ['A', 'B', 'D', 'E', 'G', 'H', 'J', 'K', 'L', 'N', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Z'];
    final rand = Random();
    String letterStr = '';
    for (int i = 0; i < 3; i++) {
      letterStr += allowed[rand.nextInt(allowed.length)];
    }
    return letterStr;
  }

  void reset() {
    emit(UploadImageFileInitial());
  }
}

// Top-level function required by compute() — runs in a separate isolate
String _convertImageToBase64(String path) {
  try {
    final bytes = File(path).readAsBytesSync();
    if (bytes.isEmpty) return '';
    return base64Encode(bytes);
  } catch (e) {
    return '';
  }
}