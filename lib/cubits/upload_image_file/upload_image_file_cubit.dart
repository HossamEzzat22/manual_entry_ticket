import 'dart:io';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
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

      // Convert the FULL image to base64 in a background isolate.
      // This full-resolution JPEG is what feeds the YOLO plate detector.
      final base64Image = await compute(_convertImageToBase64, imagePath);

      if (base64Image.isEmpty) {
        emit(UploadImageFilePickFailure("Failed to process captured photo"));
        await LogHelper.log('CAMERA', 'Base64 conversion failed for: $imagePath');
        return;
      }

      // Build a SEPARATE resized copy (longest side 720px, JPEG q80) for
      // server upload — small payload, fast upload.
      // Falls back to the full image if resize fails so upload is never lost.
      String uploadBase64 = await compute(_resizeImageForUpload, imagePath);
      if (uploadBase64.isEmpty) {
        uploadBase64 = base64Image;
        await LogHelper.log('CAMERA',
            'Upload resize failed — falling back to full image for upload');
      } else {
        await LogHelper.log('CAMERA',
            'Upload image resized (base64 len: ${uploadBase64.length}, full: ${base64Image.length})');
      }

      // Save full base64 to SharedPreferences
      await SharedPreferenceHelper.saveData(
        key: SharedPreferencesKeys.capturedImagePath,
        value: base64Image,
      );

      await LogHelper.log('CAMERA', 'Photo converted to base64 and saved to SharedPreferences');

      // Emit immediately — photo appears in UI with no delay
      emit(UploadImageFileCameraSuccess(
        originalImagePath: imagePath,
        base64Image: base64Image,
        uploadBase64: uploadBase64,
      ));

      // If AI is disabled stop here — user fills plate manually
      if (!isAiEnabled) {
        await LogHelper.log('CAMERA', 'AI OCR disabled — skipping analysis, manual plate entry mode');
        return;
      }

      // No delay — go straight into the OCR pipeline
      await runOcrAnalysis(imagePath, base64Image, uploadBase64);
    } catch (e, stackTrace) {
      await LogHelper.logException('Failed to capture photo', e, stackTrace);
      emit(UploadImageFilePickFailure(e.toString()));
    }
  }


  Future<void> runOcrAnalysis(
      String imagePath, String base64Image, String uploadBase64) async {
    emit(UploadImageFileOcrLoading(imagePath));
    await LogHelper.log('AI_OCR', 'Starting plate detection on image: $imagePath');

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
        uploadBase64: uploadBase64,
        message: "Plate detection failed — please enter the plate manually.",
      ));
      return;
    }

    if (croppedBase64 == null || croppedBase64.isEmpty) {
      await LogHelper.log('AI_OCR', 'No plate detected in image');
      emit(UploadImageFileOcrUnavailable(
        originalImagePath: imagePath,
        base64Image: base64Image,
        uploadBase64: uploadBase64,
        message: "Could not detect a plate in this photo.\nPlease take a clearer photo or enter the plate number manually.",
      ));
      return;
    }

    // Persist crop to temp file for UI preview
    final platePath = await _writeBase64ToTempPng(croppedBase64);
    await LogHelper.log('AI_OCR', 'Plate cropped (base64 length: ${croppedBase64.length})');

    // ── Step 2: remote OCR ───────────────────────────────────────────────
    try {
      final result = await PlateOcrApiService.recognizePlate(croppedBase64);
      await LogHelper.log('AI_OCR',
          'OCR result: ${result.raw} → ${result.numbers} ${result.letters}');

      emit(UploadImageFileOcrSuccess(
        originalImagePath: imagePath,
        base64Image: base64Image,
        uploadBase64: uploadBase64,
        plateImagePath: platePath ?? imagePath,
        plateNumbers: result.numbers,
        plateLetters: result.letters,
      ));
    } on PlateOcrException catch (e, stackTrace) {
      await LogHelper.logException('OCR API failed', e, stackTrace);
      emit(UploadImageFileOcrUnavailable(
        originalImagePath: imagePath,
        base64Image: base64Image,
        uploadBase64: uploadBase64,
        plateImagePath: platePath,
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




String _convertImageToBase64(String path) {
  try {
    final bytes = File(path).readAsBytesSync();
    if (bytes.isEmpty) return '';
    return base64Encode(bytes);
  } catch (e) {
    return '';
  }
}


const int _uploadMaxSide = 720;

String _resizeImageForUpload(String path) {
  try {
    final bytes = File(path).readAsBytesSync();
    if (bytes.isEmpty) return '';

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return '';

    img.Image resized = decoded;
    if (decoded.width > _uploadMaxSide || decoded.height > _uploadMaxSide) {
      resized = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: _uploadMaxSide)
          : img.copyResize(decoded, height: _uploadMaxSide);
    }

    final jpg = img.encodeJpg(resized, quality: 80);
    return base64Encode(jpg);
  } catch (e) {
    return '';
  }
}