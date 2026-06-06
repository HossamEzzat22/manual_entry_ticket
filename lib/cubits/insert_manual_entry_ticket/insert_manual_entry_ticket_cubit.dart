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

  // Translates C# format structure: _ticketType + "{0}{6}{1}{7}{2}{8}{3}{9}{4}{10}{5}{11}"
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

    // Now carParkId is available from login response stored in SharedPreferences
    final carParkId = SharedPreferenceHelper.getData(
        key: SharedPreferencesKeys.carParkId) as String? ?? '0';

    return "$ticketType$hh${r[0]}$mm${r[1]}$dd${r[2]}$MM${second[0]}$yy${second[1]}$constVal$carParkId";
  }


  /// Submits a ticket. The user ALWAYS sees success — if the API fails (or the
  /// image upload fails), the ticket is queued in SQLite and retried later by
  /// [PendingTicketRetryService]. The same locally-generated [ticketNumber] is
  /// reused on retry so the server can dedupe.
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
    final carParkId = SharedPreferenceHelper.getData(key: SharedPreferencesKeys.carParkId) as String? ?? "0";

    final deviceIdRaw = SharedPreferenceHelper.getData(key: SharedPreferencesKeys.deviceID);
    final deviceId = int.tryParse(deviceIdRaw?.toString() ?? '') ?? 0;
    // final token = SharedPreferenceHelper.getData(key: SharedPreferencesKeys.token) as String? ?? "";

    final entrySyncTime = DateTime.now().toIso8601String();

    // 2. Generate ticket number + combine plate fields → NNNNLLL format
    final ticketNo = generateTicketNumber();
    final plate = "$plateNumbers$plateLetters".toUpperCase();
    final hasImage = base64Image != null && base64Image.isNotEmpty;

    // ── STEP 1: InsertEntryTicket ──────────────────────────────────────────
    bool inserted = false;
    try {
      inserted = await TicketApiService.insertEntryTicket(
        deviceId: deviceId,
        plate: plate,
        ticketNumber: ticketNo,
        // token: token,
        entrySyncTime: entrySyncTime,
      );
    } catch (e, stackTrace) {
      await LogHelper.logException('InsertEntryTicket failed — will queue', e, stackTrace);
    }

    // ── STEP 2: UpdateEntryTicketImage (only if insert succeeded) ──────────
    bool imageDone = !hasImage; // nothing to upload counts as done
    if (inserted && hasImage) {
      emit(InsertManualEntryTicketImageUploadingState());
      try {
        imageDone = await TicketApiService.updateEntryTicketImage(
          deviceId: deviceId,
          ticketNumber: ticketNo,
          base64Image: base64Image,
          // token: token,
        );
      } catch (e, stackTrace) {
        await LogHelper.logException('UpdateEntryTicketImage failed — will queue', e, stackTrace);
        imageDone = false;
      }
    }

    // ── Queue whatever did not complete ────────────────────────────────────
    final now = DateTime.now().toIso8601String();
    if (!inserted) {
      // Whole ticket failed — queue insert (+ image if we have one).
      await PendingTicketDb.enqueue(PendingTicket(
        deviceId: deviceId,
        plate: plate,
        ticketNumber: ticketNo,
        base64Image: hasImage ? base64Image : null,
        needsInsert: true,
        needsImage: hasImage,
        createdAt: now, entrySyncTime: entrySyncTime,
      ));
      await LogHelper.log('OUTBOX',
          'Queued ticket $ticketNo for retry (insert failed, plate=$plate, imageQueued=$hasImage)');
    } else if (!imageDone) {
      // Insert succeeded but image upload failed — queue an image-only retry.
      await PendingTicketDb.enqueue(PendingTicket(
        deviceId: deviceId,
        plate: plate,
        ticketNumber: ticketNo,
        base64Image: base64Image,
        needsInsert: false,
        needsImage: true,
        createdAt: now, entrySyncTime: entrySyncTime,
      ));
      await LogHelper.log('OUTBOX',
          'Queued image-only retry for ticket $ticketNo (insert ok, image failed)');
    } else {
      await LogHelper.log('API', 'Ticket $ticketNo submitted successfully (plate=$plate)');
    }

    // Free the cached base64 — the queued copy (if any) lives in SQLite now.
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
    SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.capturedImagePath);
  }

  void reset() {
    emit(InsertManualEntryTicketInitial());
  }


}