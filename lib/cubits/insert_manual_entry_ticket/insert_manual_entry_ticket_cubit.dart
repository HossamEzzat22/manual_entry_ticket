import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:manual_entry_ticket/services/log_helper/log_helper.dart';

import '../../services/pending_ticket/pending_ticket.dart';
import '../../services/pending_ticket/pending_ticket_db.dart';
import '../../services/ticket_api/ticket_api_service.dart';
import '../../services/sp_helper/sp_helper.dart';
import '../../services/sp_helper/sp_keys.dart';

part 'insert_manual_entry_ticket_state.dart';

class InsertManualEntryTicketCubit extends Cubit<InsertManualEntryTicketState> {
  InsertManualEntryTicketCubit() : super(InsertManualEntryTicketInitial());

  String generateTicketNumber() {
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

    final carParkId = SharedPreferenceHelper.getData(
        key: SharedPreferencesKeys.carParkId) as String? ?? '0';

    return "$ticketType$hh${r[0]}$mm${r[1]}$dd${r[2]}$MM${second[0]}$yy${second[1]}$constVal$carParkId";
  }

  /// Submits a ticket.
  ///
  /// Behavior based on [isAiEnabled] and image params:
  /// ─────────────────────────────────────────────────────────────────────────
  /// AI ON  + photo taken  → insert ticket  +  upload image
  /// AI ON  + no photo     → BLOCKED in UI before this is ever called
  /// AI OFF                → insert ticket only, image upload is fully skipped
  /// ─────────────────────────────────────────────────────────────────────────
  ///
  /// Always emits [InsertManualEntryTicketSuccessState] to the user.
  /// If the API fails, the ticket is queued in SQLite and retried later
  /// by [PendingTicketRetryService].
  Future<void> insertManualTicket({
    required bool isAiEnabled,
    required String? imagePath,
    required String? base64Image,
    required String? uploadBase64,
    required String plateNumbers,
    required String plateLetters,
  }) async {
    emit(InsertManualEntryTicketLoadingState());

    // 1. Read device info from SharedPreferences
    final facilityId = SharedPreferenceHelper.getData(
        key: SharedPreferencesKeys.facilityId) as String? ??
        "0";
    final carParkId = SharedPreferenceHelper.getData(
        key: SharedPreferencesKeys.carParkId) as String? ??
        "0";
    final deviceIdRaw =
    SharedPreferenceHelper.getData(key: SharedPreferencesKeys.deviceID);
    final deviceId = int.tryParse(deviceIdRaw?.toString() ?? '') ?? 0;

    final entrySyncTime = DateTime.now().toIso8601String();

    // 2. Generate ticket number + combine plate → NNNNLLL
    final ticketNo = generateTicketNumber();
    final plate = "$plateNumbers$plateLetters".toUpperCase();

    // 3. Determine whether an image should be uploaded.
    //    When AI is OFF, imagePath/base64Image/uploadBase64 are all null
    //    (forced by the screen), so hasImage will always be false.
    //    When AI is ON but the user somehow skipped the photo (guarded by UI),
    //    hasImage will also be false and no upload is attempted.
    final imageToUpload = (uploadBase64 != null && uploadBase64.isNotEmpty)
        ? uploadBase64
        : base64Image;
    // Upload image whenever a photo exists — regardless of AI mode.
    // AI mode only controls OCR/plate detection, not image upload.
    final bool hasImage = imageToUpload != null && imageToUpload.isNotEmpty;

    await LogHelper.log(
      'TICKET',
      'insertManualTicket called — '
          'aiEnabled=$isAiEnabled, hasImage=$hasImage, plate=$plate, ticketNo=$ticketNo',
    );

    // ── STEP 1: InsertEntryTicket ──────────────────────────────────────────
    bool inserted = false;
    try {
      inserted = await TicketApiService.insertEntryTicket(
        deviceId: deviceId,
        plate: plate,
        ticketNumber: ticketNo,
        entrySyncTime: entrySyncTime,
      );
      await LogHelper.log(
          'API', 'InsertEntryTicket result=$inserted for ticketNo=$ticketNo');
    } catch (e, stackTrace) {
      await LogHelper.logException(
          'InsertEntryTicket failed — will queue', e, stackTrace);
    }

    // ── STEP 2: UpdateEntryTicketImage ─────────────────────────────────────
    // Only runs when:
    //   • AI mode is ON         (isAiEnabled = true)
    //   • A photo was taken     (hasImage = true)
    //   • Insert succeeded      (inserted = true)
    bool imageDone = !hasImage; // if no image needed → treat as done
    if (inserted && hasImage) {
      emit(InsertManualEntryTicketImageUploadingState());
      try {
        imageDone = await TicketApiService.updateEntryTicketImage(
          deviceId: deviceId,
          ticketNumber: ticketNo,
          base64Image: imageToUpload!,
        );
        await LogHelper.log(
            'API', 'UpdateEntryTicketImage result=$imageDone for ticketNo=$ticketNo');
      } catch (e, stackTrace) {
        await LogHelper.logException(
            'UpdateEntryTicketImage failed — will queue', e, stackTrace);
        imageDone = false;
      }
    } else if (!hasImage) {
      await LogHelper.log(
        'API',
        'Image upload skipped — no photo was taken, ticketNo=$ticketNo',
      );
    }

    // ── Queue whatever did not complete ────────────────────────────────────
    final now = DateTime.now().toIso8601String();
    if (!inserted) {
      // Insert failed → queue insert + image (if AI was on and had image)
      await PendingTicketDb.enqueue(PendingTicket(
        deviceId: deviceId,
        plate: plate,
        ticketNumber: ticketNo,
        base64Image: hasImage ? imageToUpload : null,
        needsInsert: true,
        needsImage: hasImage, // only retry image if AI was on
        createdAt: now,
        entrySyncTime: entrySyncTime,
      ));
      await LogHelper.log(
        'OUTBOX',
        'Queued ticket $ticketNo for retry '
            '(insert failed, plate=$plate, imageQueued=$hasImage)',
      );
    } else if (!imageDone) {
      // Insert succeeded but image upload failed → queue image-only retry
      await PendingTicketDb.enqueue(PendingTicket(
        deviceId: deviceId,
        plate: plate,
        ticketNumber: ticketNo,
        base64Image: imageToUpload,
        needsInsert: false,
        needsImage: true,
        createdAt: now,
        entrySyncTime: entrySyncTime,
      ));
      await LogHelper.log(
        'OUTBOX',
        'Queued image-only retry for ticket $ticketNo '
            '(insert ok, image failed)',
      );
    } else {
      await LogHelper.log(
        'API',
        'Ticket $ticketNo submitted successfully '
            '(plate=$plate, imageUploaded=$hasImage)',
      );
    }

    // Free the cached base64 — queued copy (if any) lives in SQLite now
    _clearBase64Cache();

    // ── Always report success to the user ──────────────────────────────────
    emit(InsertManualEntryTicketSuccessState(
      ticketNo: ticketNo,
      plate: plate,
      facilityId: int.tryParse(facilityId) ?? 0,
      carParkId: int.tryParse(carParkId) ?? 0,
      clientId: 0,
      entryTime: '',
      status: '',
    ));
  }

  void _clearBase64Cache() {
    SharedPreferenceHelper.removeData(
        key: SharedPreferencesKeys.capturedImagePath);
  }

  void reset() {
    emit(InsertManualEntryTicketInitial());
  }
}