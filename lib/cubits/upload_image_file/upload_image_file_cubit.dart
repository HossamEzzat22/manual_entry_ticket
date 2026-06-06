import 'dart:io';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manual_entry_ticket/services/log_helper/log_helper.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/calling_ocr_service/calling_ocr_service.dart';
import '../../services/plate_channel/plate_channel_service.dart';
import '../../services/sp_helper/sp_helper.dart';
import '../../services/sp_helper/sp_keys.dart';

part 'upload_image_file_state.dart';

class UploadImageFileCubit extends Cubit<UploadImageFileState> {
  UploadImageFileCubit() : super(UploadImageFileInitial());

  final ImagePicker _picker = ImagePicker();

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

      // Start the real detect → crop → OCR pipeline.
      await runOcrAnalysis(imagePath, base64Image);
    } catch (e, stackTrace) {
      await LogHelper.logException('Failed to capture photo', e, stackTrace);
      emit(UploadImageFilePickFailure(e.toString()));
    }
  }

  /// Full AI pipeline for a captured photo:
  ///  1. native YOLO detect + crop the plate (base64 PNG)
  ///  2. remote OCR API to read the plate text
  ///
  /// On any miss/failure we fall back to manual entry (photo kept, fields empty)
  /// rather than blocking the user.
  Future<void> runOcrAnalysis(String imagePath, String base64Image) async {
    // Keep the captured photo visible while the pipeline runs.
    emit(UploadImageFileOcrLoading(imagePath));

    await LogHelper.log('AI_OCR', 'Starting plate detection on image: $imagePath');

    // ── Step 1: native detection + crop ──────────────────────────────────
    String? croppedBase64;
    try {
      final detection = await PlateChannelService.detectAndCropPlate(base64Image);
      croppedBase64 = detection.croppedBase64;
      if (detection.diag != null) {
        await LogHelper.log('AI_OCR', 'Detector: ${detection.diag}');
      }
    } on PlateDetectionException catch (e, stackTrace) {
      await LogHelper.logException('Native plate detection failed', e, stackTrace);
      emit(UploadImageFileOcrUnavailable(
        originalImagePath: imagePath,
        base64Image: base64Image,
        message: "Plate detection failed — please enter the plate manually.",
      ));
      return;
    }

    if (croppedBase64 == null || croppedBase64.isEmpty) {
      await LogHelper.log('AI_OCR', 'No plate detected in image');
      emit(UploadImageFileOcrUnavailable(
        originalImagePath: imagePath,
        base64Image: base64Image,
        message: "Could not detect a plate in this photo.\nPlease take a clearer photo or enter the plate number manually.",
      ));
      return;
    }

    // Persist the crop to a temp file so the UI can preview it.
    final platePath = await _writeBase64ToTempPng(croppedBase64);
    await LogHelper.log('AI_OCR', 'Plate cropped (base64 length: ${croppedBase64.length})');

    // ── Step 2: remote OCR ───────────────────────────────────────────────
    try {
      final result = await PlateOcrApiService.recognizePlate(croppedBase64);
      await LogHelper.log('AI_OCR', 'OCR result: ${result.raw} → ${result.numbers} ${result.letters}');

      emit(UploadImageFileOcrSuccess(
        originalImagePath: imagePath,
        base64Image: base64Image, // original full photo — used for upload
        plateImagePath: platePath ?? imagePath,
        plateNumbers: result.numbers,
        plateLetters: result.letters,
      ));
    } on PlateOcrException catch (e, stackTrace) {
      await LogHelper.logException('OCR API failed', e, stackTrace);
      emit(UploadImageFileOcrUnavailable(
        originalImagePath: imagePath,
        base64Image: base64Image,
        plateImagePath: platePath, // we still have the crop to show
        message: "Could not read the plate — please enter it manually.",
      ));
    }
  }

  /// Writes a base64 PNG to a temp file and returns its path (null on failure).
  Future<String?> _writeBase64ToTempPng(String base64Png) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/plate_crop_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(base64Decode(base64Png));
      return file.path;
    } catch (e, stackTrace) {
      await LogHelper.logException('Failed to write plate crop to temp file', e, stackTrace);
      return null;
    }
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