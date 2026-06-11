import 'dart:io';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:manual_entry_ticket/l10n/app_localizations.dart';
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

  Future<void> capturePhoto({
    required bool isAiEnabled,
    required AppLocalizations l10n,
  }) async {
    emit(UploadImageFilePickLoading());

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo == null) {
        emit(UploadImageFilePickFailure(l10n.cameraCaptureCanceled));
        await LogHelper.log('CAMERA', 'User canceled camera capture');
        return;
      }

      final imagePath = photo.path;
      await LogHelper.log('CAMERA', 'Photo captured successfully: $imagePath');

      final base64Image = await compute(_convertImageToBase64, imagePath);

      if (base64Image.isEmpty) {
        emit(UploadImageFilePickFailure(l10n.failedToProcessPhoto));
        await LogHelper.log('CAMERA', 'Base64 conversion failed');
        return;
      }

      String uploadBase64 = await compute(_resizeImageForUpload, imagePath);

      if (uploadBase64.isEmpty) {
        uploadBase64 = base64Image;
      }

      await SharedPreferenceHelper.saveData(
        key: SharedPreferencesKeys.capturedImagePath,
        value: base64Image,
      );

      emit(UploadImageFileCameraSuccess(
        originalImagePath: imagePath,
        base64Image: base64Image,
        uploadBase64: uploadBase64,
      ));

      if (!isAiEnabled) {
        await LogHelper.log('CAMERA', 'AI disabled — manual mode');
        return;
      }

      await runOcrAnalysis(imagePath, base64Image, uploadBase64, l10n);
    } catch (e, stackTrace) {
      await LogHelper.logException('Failed to capture photo', e, stackTrace);
      emit(UploadImageFilePickFailure(e.toString()));
    }
  }

  Future<void> runOcrAnalysis(
      String imagePath,
      String base64Image,
      String uploadBase64,
      AppLocalizations l10n,
      ) async {
    emit(UploadImageFileOcrLoading(imagePath));

    await LogHelper.log('AI_OCR', 'Starting detection: $imagePath');

    String? croppedBase64;

    try {
      final detection =
      await PlateChannelService.detectAndCropPlate(base64Image);

      croppedBase64 = detection.croppedBase64;

      if (detection.diag != null) {
        await LogHelper.log('AI_OCR', detection.diag!);
      }
    } on PlateDetectionException catch (e, stackTrace) {
      await LogHelper.logException('Plate detection failed', e, stackTrace);

      emit(UploadImageFileOcrUnavailable(
        originalImagePath: imagePath,
        base64Image: base64Image,
        uploadBase64: uploadBase64,
        message: l10n.plateDetectionFailed,
      ));
      return;
    }

    if (croppedBase64 == null || croppedBase64.isEmpty) {
      emit(UploadImageFileOcrUnavailable(
        originalImagePath: imagePath,
        base64Image: base64Image,
        uploadBase64: uploadBase64,
        message: l10n.plateDetectionError,
      ));
      return;
    }

    final platePath = await _writeBase64ToTempPng(croppedBase64);

    try {
      final result =
      await PlateOcrApiService.recognizePlate(croppedBase64);

      await LogHelper.log(
        'AI_OCR',
        'OCR result: ${result.raw}',
      );

      emit(UploadImageFileOcrSuccess(
        originalImagePath: imagePath,
        base64Image: base64Image,
        uploadBase64: uploadBase64,
        plateImagePath: platePath ?? imagePath,
        plateNumbers: result.numbers,
        plateLetters: result.letters,
      ));
    } on PlateOcrException catch (e, stackTrace) {
      await LogHelper.logException('OCR failed', e, stackTrace);

      emit(UploadImageFileOcrUnavailable(
        originalImagePath: imagePath,
        base64Image: base64Image,
        uploadBase64: uploadBase64,
        plateImagePath: platePath,
        message: l10n.ocrPlateNotReadable,
      ));
    }
  }

  Future<String?> _writeBase64ToTempPng(String base64Png) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/plate_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(base64Decode(base64Png));
      return file.path;
    } catch (_) {
      return null;
    }
  }

  void reset() => emit(UploadImageFileInitial());
}

// ---------------- helpers ----------------

String _convertImageToBase64(String path) {
  try {
    final bytes = File(path).readAsBytesSync();
    return base64Encode(bytes);
  } catch (_) {
    return '';
  }
}

const int _uploadMaxSide = 720;

String _resizeImageForUpload(String path) {
  try {
    final bytes = File(path).readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return '';

    final resized = decoded.width > _uploadMaxSide
        ? img.copyResize(decoded, width: _uploadMaxSide)
        : decoded;

    final jpg = img.encodeJpg(resized, quality: 80);
    return base64Encode(jpg);
  } catch (_) {
    return '';
  }
}