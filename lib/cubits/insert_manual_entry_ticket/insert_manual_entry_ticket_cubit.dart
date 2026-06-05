import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:manual_entry_ticket/services/log_helper/log_helper.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/network/dio_helper.dart';
import '../../services/sp_helper/sp_helper.dart';
import '../../services/sp_helper/sp_keys.dart';

part 'insert_manual_entry_ticket_state.dart';

class InsertManualEntryTicketCubit extends Cubit<InsertManualEntryTicketState> {
  InsertManualEntryTicketCubit() : super(InsertManualEntryTicketInitial());

  // Translates C# format structure: _ticketType + "{0}{6}{1}{7}{2}{8}{3}{9}{4}{10}{5}{11}"
  String generateTicketNumber(String carParkId) {
    final time = DateTime.now();
    final rand = Random();
    final r = rand.nextInt(1000).toString().padLeft(3, '0');
    final second = time.second.toString().padLeft(2, '0');

    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final dd = time.day.toString().padLeft(2, '0');
    final MM = time.month.toString().padLeft(2, '0');
    final yy = (time.year % 100).toString().padLeft(2, '0');
    const ticketType = "1";
    const constVal = "01";
    // carParkId = SharedPreferenceHelper.getData(key: SharedPreferencesKeys.carparkId);

    return "$ticketType$hh${r[0]}$mm${r[1]}$dd${r[2]}$MM${second[0]}$yy${second[1]}$constVal$carParkId";
  }

  Future<void> insertManualTicket({
    required bool isAiEnabled,
    required String? imagePath,
    required String? base64Image,
    required String plateNumbers,
    required String plateLetters,
  }) async {
    emit(InsertManualEntryTicketLoadingState());

    // 1. Read device info from SharedPreferences
    final facilityId = SharedPreferenceHelper.getData(key: SharedPreferencesKeys.facilityId) as String? ?? "0";
    final deviceIdRaw = SharedPreferenceHelper.getData(key: SharedPreferencesKeys.deviceID);
    final deviceId = int.tryParse(deviceIdRaw?.toString() ?? '') ?? 0;
    final token = SharedPreferenceHelper.getData(key: SharedPreferencesKeys.token) as String? ?? "";

    // 2. Generate ticket number
    final ticketNo = generateTicketNumber(facilityId);

    // 3. Combine plate fields → NNNNLLL format
    final plate = "$plateNumbers$plateLetters".toUpperCase();

    // 4. Save image locally for record-keeping (non-blocking)
    // if (imagePath != null && imagePath.isNotEmpty) {
    //   try {
    //     final localPath = await _saveImageLocally(imagePath, ticketNo);
    //     await LogHelper.log('FILE_STORAGE', 'Saved photo locally: $localPath');
    //   } catch (e, stackTrace) {
    //     await LogHelper.logException('Failed to copy captured file locally', e, stackTrace);
    //   }
    // }

    // ── STEP 1: InsertEntryTicket ──────────────────────────────────────────
    // Server uses [FromForm] → must send as FormData, NOT JSON
    final insertForm = FormData.fromMap({
      "deviceId": deviceId,
      "plate": plate,
      "ticketNumber": ticketNo,
    });

    await LogHelper.logApiRequest('POST', 'api/ManualTicket/InsertEntryTicket', data: {
      "deviceId": deviceId,
      "plate": plate,
      "ticketNumber": ticketNo,
    });

    try {
      final insertResponse = await DioHelper.postData(
        url: 'api/ManualTicket/InsertEntryTicket',
        token: token,
        data: insertForm,
      );

      final insertBody = insertResponse.data as Map<String, dynamic>;

      if (insertBody['success'] != true) {
        final msg = insertBody['message']?.toString() ?? 'Insert failed';
        await LogHelper.log('API', 'InsertEntryTicket rejected: $msg');
        emit(InsertManualEntryTicketErrorState(message: msg));
        return;
      }

      await LogHelper.log('API', 'InsertEntryTicket success: ticketNo=$ticketNo, plate=$plate');

      // ── STEP 2: UpdateEntryTicketImage ──────────────────────────────────
      // Only upload image if base64 is available
      if (base64Image != null && base64Image.isNotEmpty) {
        emit(InsertManualEntryTicketImageUploadingState());

        // Print base64 string to Android Studio output for verification
        developer.log(
          'BASE64_IMAGE [length=${base64Image.length}]: $base64Image',
          name: 'IMAGE_UPLOAD',
        );

        await LogHelper.log('IMAGE_UPLOAD', 'Uploading entry image for ticketNo=$ticketNo [base64 length: ${base64Image.length}]');

        final imageForm = FormData.fromMap({
          "deviceId": deviceId,
          "ticketNumber": ticketNo,
          "entryImageBase64": base64Image,
        });

        await LogHelper.logApiRequest('POST', 'api/ManualTicket/UpdateEntryTicketImage', data: {
          "deviceId": deviceId,
          "ticketNumber": ticketNo,
          "entryImageBase64": "[base64 length: ${base64Image.length}]",
        });

        try {
          final imageResponse = await DioHelper.postData(
            url: 'api/ManualTicket/UpdateEntryTicketImage',
            token: token,
            data: imageForm,
          );

          final imageBody = imageResponse.data as Map<String, dynamic>;

          if (imageBody['success'] == true) {
            await LogHelper.log('IMAGE_UPLOAD', 'Entry image uploaded successfully. Path: ${imageBody['imagePath']} | Size: ${imageBody['imageSize']}');
          } else {
            await LogHelper.log('IMAGE_UPLOAD', 'Image upload rejected: ${imageBody['message']}');
            // Non-fatal — ticket was already inserted successfully
          }
        } catch (e, stackTrace) {
          await LogHelper.logException('UpdateEntryTicketImage API error (non-fatal)', e, stackTrace);
          // Non-fatal — ticket insert already succeeded
        }

        // Clear base64 from SharedPreferences after upload attempt to free memory
        _clearBase64Cache();
        await LogHelper.log('IMAGE_UPLOAD', 'Cleared base64 from SharedPreferences');
      }

      // ── Emit final success with data from InsertEntryTicket response ────
      emit(InsertManualEntryTicketSuccessState(
        ticketNo: insertBody['ticketNo']?.toString() ?? ticketNo,
        plate: insertBody['plate']?.toString() ?? plate,
        facilityId: insertBody['facilityId'] as int? ?? 0,
        carParkId: insertBody['carParkId'] as int? ?? 0,
        clientId: insertBody['clientId'] as int? ?? 0,
        entryTime: insertBody['entryTime']?.toString() ?? '',
        status: insertBody['status']?.toString() ?? '',
      ));

    } catch (e, stackTrace) {
      String errorMessage = e.toString();
      if (e is DioException && e.response != null) {
        final responseBody = e.response!.data;
        await LogHelper.log('API', 'Server error response: $responseBody');
        if (responseBody is Map) {
          errorMessage = responseBody['message']?.toString() ?? errorMessage;
        } else {
          errorMessage = responseBody.toString();
        }
      }
      await LogHelper.logException('InsertManualTicket API error', e, stackTrace);
      emit(InsertManualEntryTicketErrorState(message: errorMessage));
    }
  }

  // Future<String> _saveImageLocally(String srcPath, String ticketNo) async {
  //   final file = File(srcPath);
  //   if (await file.exists()) {
  //     final appDir = await getApplicationDocumentsDirectory();
  //     final targetPath = '${appDir.path}/$ticketNo.jpg';
  //     await file.copy(targetPath);
  //     return targetPath;
  //   }
  //   throw Exception("Captured camera file not found at: $srcPath");
  // }

  void _clearBase64Cache() {
    SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.capturedImagePath);
  }

  void reset() {
    emit(InsertManualEntryTicketInitial());
  }
}