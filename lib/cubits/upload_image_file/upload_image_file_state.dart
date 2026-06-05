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
  final String base64Image;
  UploadImageFileCameraSuccess({
    required this.originalImagePath,
    required this.base64Image,
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
  final String base64Image;
  final String plateImagePath;
  final String plateNumbers;
  final String plateLetters;

  UploadImageFileOcrSuccess({
    required this.originalImagePath,
    required this.base64Image,
    required this.plateImagePath,
    required this.plateNumbers,
    required this.plateLetters,
  });
}