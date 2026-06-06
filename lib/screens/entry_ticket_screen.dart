import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../core/constants/app_colors.dart';
import '../cubits/app_settings/app_settings_cubit.dart';
import '../cubits/insert_manual_entry_ticket/insert_manual_entry_ticket_cubit.dart';
import '../cubits/upload_image_file/upload_image_file_cubit.dart';
import '../services/sp_helper/sp_helper.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/loading_dialog.dart';
import '../widgets/success_dialog.dart';
import '../widgets/gaps.dart';
import '../widgets/logs_bottom_sheet.dart';

class EntryTicketScreen extends StatefulWidget {
  const EntryTicketScreen({super.key});

  @override
  State<EntryTicketScreen> createState() => _EntryTicketScreenState();
}

class _EntryTicketScreenState extends State<EntryTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _numbersController = TextEditingController();
  final TextEditingController _lettersController = TextEditingController();


  /// Initializes the screen state and attaches listeners to:
  /// - Prevent plate numbers from starting with '0'.
  /// - Convert plate letters to uppercase.
  /// - Filter plate letters so only allowed Saudi plate characters remain.
  @override
  void initState() {
    super.initState();

    _numbersController.addListener(() {
      String text = _numbersController.text;
      if (text.startsWith('0')) {
        _numbersController.text = text.substring(1);
        _numbersController.selection = TextSelection.fromPosition(
          TextPosition(offset: _numbersController.text.length),
        );
      }
    });

    _lettersController.addListener(() {
      const allowedLetters = {
        'A', 'B', 'D', 'E', 'G', 'H', 'J', 'K', 'L', 'N', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Z'
      };
      String text = _lettersController.text.toUpperCase();
      String filtered = '';
      for (int i = 0; i < text.length; i++) {
        final char = text[i];
        if (allowedLetters.contains(char)) {
          filtered += char;
        }
      }
      if (filtered != _lettersController.text) {
        _lettersController.text = filtered;
        _lettersController.selection = TextSelection.fromPosition(
          TextPosition(offset: _lettersController.text.length),
        );
      }
    });
  }


  /// Releases all TextEditingController resources and removes listeners
  /// when the screen is disposed to prevent memory leaks.
  @override
  void dispose() {
    _numbersController.dispose();
    _lettersController.dispose();
    super.dispose();
  }
  void _openImageFullScreen(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Pinch-to-zoom image
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 40.h,
              right: 16.w,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 22.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Extracts imagePath and base64Image from the current upload state.
  /// Returns null for both if no photo has been captured yet.
  ({String? imagePath, String? base64Image}) _getPhotoData(UploadImageFileState uploadState) {
    if (uploadState is UploadImageFileCameraSuccess) {
      return (imagePath: uploadState.originalImagePath, base64Image: uploadState.base64Image);
    } else if (uploadState is UploadImageFileOcrSuccess) {
      return (imagePath: uploadState.originalImagePath, base64Image: uploadState.base64Image);
    } else if (uploadState is UploadImageFileOcrUnavailable) {
      return (imagePath: uploadState.originalImagePath, base64Image: uploadState.base64Image);
    }
    return (imagePath: null, base64Image: null);
  }

  /// Builds the Manual Entry Ticket screen UI.
  ///
  /// Responsibilities:
  /// - Listens to image upload and OCR state changes.
  /// - Displays loading, success, and error dialogs.
  /// - Allows the user to capture a vehicle photo.
  /// - Displays the captured image and AI-detected plate preview.
  /// - Collects plate number and plate letters input.
  /// - Validates user input.
  /// - Submits the entry ticket request.
  /// - Provides an option to share application logs.
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UploadImageFileCubit, UploadImageFileState>(
          listener: (context, state) {
            if (state is UploadImageFileOcrLoading) {
              LoadingDialog.show(context, "AI OCR: Extracting plate details...");
            } else if (state is UploadImageFileOcrSuccess) {
              LoadingDialog.hide(context);
              _numbersController.text = state.plateNumbers;
              _lettersController.text = state.plateLetters;
              CustomSnackBar.showSuccess(context, "AI Auto-detection: License plate populated!");
            } else if (state is UploadImageFileOcrUnavailable) {
              LoadingDialog.hide(context);
              CustomSnackBar.showInfo(context, state.message);
            } else if (state is UploadImageFilePickFailure) {
              LoadingDialog.hide(context);
              CustomSnackBar.showError(context, "Failed to capture: ${state.error}");
            }
          },
        ),
        BlocListener<InsertManualEntryTicketCubit, InsertManualEntryTicketState>(
          listener: (context, state) {
            // Always hide any existing loading dialog first
            LoadingDialog.hide(context);

            if (state is InsertManualEntryTicketLoadingState) {
              LoadingDialog.show(context, "Submitting Entry Ticket...");
            } else if (state is InsertManualEntryTicketImageUploadingState) {
              // LoadingDialog.show(context, "Uploading vehicle photo...");
            } else if (state is InsertManualEntryTicketSuccessState) {
              SuccessDialog.show(context);
              _numbersController.clear();
              _lettersController.clear();
              context.read<UploadImageFileCubit>().reset();
            } else if (state is InsertManualEntryTicketErrorState) {
              CustomSnackBar.showError(context, "Submission failed: ${state.message}");
            }
          },
        ),
      ],
      child: AppScaffold(
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Header ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Manual Ticket Entry",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Automatic AI",
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.subtitleText,
                        ),
                      ),
                      Gaps.w4,
                      BlocBuilder<AppSettingsCubit, AppSettingsState>(
                        builder: (context, state) {
                          return Switch.adaptive(
                            value: state.isAiAnalysisEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              context.read<AppSettingsCubit>().toggleAiAnalysis(val);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFE2E2E2)),

              // ── Step 1: Take Photo Button ─────────────────────────────────
              CustomButton(
                label: "TAKE PHOTO",
                icon: Icons.photo_camera,
                isPrimary: true,
                onPressed: () {
                  final isAiEnabled = context.read<AppSettingsCubit>().state.isAiAnalysisEnabled;
                  context.read<UploadImageFileCubit>().capturePhoto(isAiEnabled: isAiEnabled);
                },
              ),
              Gaps.h16,

              // ── Step 2: Captured Photo Box ────────────────────────────────
              Text(
                "Captured Photo",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBlue,
                ),
              ),
              Gaps.h8,
              BlocBuilder<UploadImageFileCubit, UploadImageFileState>(
                builder: (context, fileState) {
                  String? originalPath;
                  if (fileState is UploadImageFileCameraSuccess) {
                    originalPath = fileState.originalImagePath;
                  } else if (fileState is UploadImageFileOcrLoading) {
                    originalPath = fileState.originalImagePath;
                  } else if (fileState is UploadImageFileOcrSuccess) {
                    originalPath = fileState.originalImagePath;
                  } else if (fileState is UploadImageFileOcrUnavailable) {
                    originalPath = fileState.originalImagePath;
                  }

                  return Container(
                    height: 180.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(10.w),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: originalPath != null
                        ? GestureDetector(
                      onTap: () => _openImageFullScreen(context, originalPath!),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.w),
                            child: Image.file(
                              File(originalPath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 180.h,
                            ),
                          ),
                          // Tap hint icon
                          Positioned(
                            bottom: 8.h,
                            right: 8.w,
                            child: Container(
                              padding: EdgeInsets.all(5.w),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(6.w),
                              ),
                              child: Icon(
                                Icons.zoom_in_rounded,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera_back_outlined,
                            size: 36.sp,
                            color: Colors.grey[400],
                          ),
                          Gaps.h8,
                          Text(
                            "No photo captured",
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Gaps.h24,

              // ── Step 3: OCR Result Section ────────────────────────────────
              BlocBuilder<AppSettingsCubit, AppSettingsState>(
                builder: (context, settingsState) {
                  final bool aiEnabled = settingsState.isAiAnalysisEnabled;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        aiEnabled ? "AI Plate Detection Result" : "Plate Detection Result",
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      Gaps.h8,

                      // Plate crop preview — only when AI is enabled
                      if (aiEnabled)
                        BlocBuilder<UploadImageFileCubit, UploadImageFileState>(
                          builder: (context, fileState) {
                            final bool isOcrLoading = fileState is UploadImageFileOcrLoading;
                            String? platePath;
                            if (fileState is UploadImageFileOcrSuccess) {
                              platePath = fileState.plateImagePath;
                            } else if (fileState is UploadImageFileOcrUnavailable) {
                              platePath = fileState.plateImagePath;
                            }

                            return Column(
                              children: [
                                Container(
                                  height: 100.h,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(8.w),
                                    border: Border.all(color: AppColors.fieldBorder),
                                  ),
                                  child: isOcrLoading
                                      ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SpinKitPulse(
                                          color: AppColors.primary,
                                          size: 26.sp,
                                        ),
                                        Gaps.h8,
                                        Text(
                                          "Detecting plate...",
                                          style: TextStyle(
                                            fontSize: 9.sp,
                                            color: AppColors.subtitleText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                      : platePath != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8.w),
                                    child: Image.file(
                                      File(platePath),
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                    ),
                                  )
                                      : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.crop_free_rounded,
                                          size: 26.sp,
                                          color: Colors.grey[400],
                                        ),
                                        Gaps.h4,
                                        Text(
                                          "Plate crop pending",
                                          style: TextStyle(
                                            fontSize: 9.sp,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Gaps.h16,
                              ],
                            );
                          },
                        ),
                    ],
                  );
                },
              ),

              // ── Step 4: Plate Number Form ─────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Plate Number",
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    Gaps.h8,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _numbersController,
                            labelText: "Digits (Max 4)",
                            hintText: "1234",
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return "Required";
                              if (val.startsWith('0')) return "Cannot start with 0";
                              return null;
                            },
                          ),
                        ),
                        Gaps.w12,
                        Expanded(
                          child: CustomTextField(
                            controller: _lettersController,
                            labelText: "Saudi Letters (Max 3)",
                            hintText: "RSD",
                            keyboardType: TextInputType.text,
                            maxLength: 3,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                            ],
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return "Required";
                              if (val.trim().length != 3) return "Must be exactly 3 letters";
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    Gaps.h8,
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6.w),
                      ),
                      child: Text(
                        "Allowed Letters: A, B, D, E, G, H, J, K, L, N, R, S, T, U, V, W, X, Z",
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                      ),
                    ),
                    Gaps.h24,

                    // ── Submit ───────────────────────────────────────────────
                    CustomButton(
                      label: "SUBMIT ENTRY TICKET",
                      onPressed: () {
                        final isAiEnabled =
                            context.read<AppSettingsCubit>().state.isAiAnalysisEnabled;
                        final uploadState =
                            context.read<UploadImageFileCubit>().state;

                        final photoData = _getPhotoData(uploadState);

                        // Photo is required in BOTH AI-on and AI-off modes
                        if (photoData.imagePath == null) {
                          CustomSnackBar.showError(
                            context,
                            "Vehicle photo is required. Please capture a photo first.",
                          );
                          return;
                        }

                        if (_formKey.currentState!.validate()) {
                          context
                              .read<InsertManualEntryTicketCubit>()
                              .insertManualTicket(
                            isAiEnabled: isAiEnabled,
                            imagePath: photoData.imagePath,
                            base64Image: photoData.base64Image,
                            plateNumbers: _numbersController.text.trim(),
                            plateLetters: _lettersController.text.trim(),
                          );
                        }
                      },
                    ),
                    Gaps.h12,

                    // ── Share Logs ───────────────────────────────────────────
                    CustomButton(
                      label: "SHARE LOGS",
                      icon: Icons.share_outlined,
                      isPrimary: false,
                      onPressed: () => LogsBottomSheet.show(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}