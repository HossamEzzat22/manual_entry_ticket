part of 'upload_image_file_cubit.dart';

sealed class UploadImageFileState {}

final class UploadImageFileInitial extends UploadImageFileState {}

final class UploadImageFilePickLoading extends UploadImageFileState {}

final class UploadImageFilePickFailure extends UploadImageFileState {
  final String error;
  UploadImageFilePickFailure(this.error);
}

final class UploadImageFileCameraSuccess extends UploadImageFileState {
  final String originalImagePath;
  final String base64Image; // full-resolution copy (OCR/reference)
  final String uploadBase64; // resized copy (≤720px) used for upload
  UploadImageFileCameraSuccess({
    required this.originalImagePath,
    required this.base64Image,
    required this.uploadBase64,
  });
}

// Carries originalImagePath so the captured photo box stays visible
// while OCR is running.
final class UploadImageFileOcrLoading extends UploadImageFileState {
  final String originalImagePath;
  UploadImageFileOcrLoading(this.originalImagePath);
}

final class UploadImageFileOcrSuccess extends UploadImageFileState {
  final String originalImagePath;
  final String base64Image; // full-resolution copy (OCR/reference)
  final String uploadBase64; // resized copy (≤720px) used for upload
  final String plateImagePath;
  final String plateNumbers;
  final String plateLetters;

  UploadImageFileOcrSuccess({
    required this.originalImagePath,
    required this.base64Image,
    required this.uploadBase64,
    required this.plateImagePath,
    required this.plateNumbers,
    required this.plateLetters,
  });
}

// AI was on but detection/OCR could not produce a plate. The photo is kept so
// the user can submit after typing the plate manually.
// [plateImagePath] is non-null when we got a crop but OCR failed (so we can
// still show the crop preview); null when no plate was detected at all.
final class UploadImageFileOcrUnavailable extends UploadImageFileState {
  final String originalImagePath;
  final String base64Image; // full-resolution copy (OCR/reference)
  final String uploadBase64; // resized copy (≤720px) used for upload
  final String? plateImagePath;
  final String message;

  UploadImageFileOcrUnavailable({
    required this.originalImagePath,
    required this.base64Image,
    required this.uploadBase64,
    required this.message,
    this.plateImagePath,
  });
}