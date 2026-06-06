import 'dart:async';

import '../log_helper/log_helper.dart';
import '../sp_helper/sp_helper.dart';
import '../sp_helper/sp_keys.dart';
import '../ticket_api/ticket_api_service.dart';
import 'pending_ticket.dart';
import 'pending_ticket_db.dart';

/// Periodically retries ticket submissions queued in [PendingTicketDb].
///
/// Runs in-app only: a flush on [start] plus one every [_interval] while the
/// app is alive. Retries resume on the next app launch.
class PendingTicketRetryService {
  PendingTicketRetryService._();
  static final PendingTicketRetryService instance = PendingTicketRetryService._();

  static const Duration _interval = Duration(minutes: 5);

  Timer? _timer;
  bool _isFlushing = false;

  void start() {
    // Fire once now (catches anything left over from a previous session)…
    flush();
    // …then on a fixed cadence.
    _timer ??= Timer.periodic(_interval, (_) => flush());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Attempts to send every queued ticket. Safe to call concurrently — a second
  /// call while one is in flight is a no-op.
  Future<void> flush() async {
    if (_isFlushing) return;
    _isFlushing = true;
    try {
      final pending = await PendingTicketDb.getAll();
      if (pending.isEmpty) return;

      // final token = SharedPreferenceHelper.getData(key: SharedPreferencesKeys.token) as String? ?? '';

      await LogHelper.log('OUTBOX', 'Retrying ${pending.length} pending ticket(s)');
      for (final ticket in pending) {
        await _process(ticket);
      }
    } catch (e, stackTrace) {
      await LogHelper.logException('Outbox flush failed', e, stackTrace);
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> _process(PendingTicket ticket) async {
    bool needsInsert = ticket.needsInsert;
    bool needsImage = ticket.needsImage;
    final hasImage = ticket.base64Image != null && ticket.base64Image!.isNotEmpty;

    // Use the original entrySyncTime stored when the ticket was first created.
    // For old rows migrated from v1 (empty string), fall back to now so the
    // request is still valid rather than sending an empty field.
    final entrySyncTime = ticket.entrySyncTime.isNotEmpty
        ? ticket.entrySyncTime
        : DateTime.now().toIso8601String();

    try {
      if (needsInsert) {
        // Reuse the SAME ticketNumber so the server can dedupe across retries.
        if (await TicketApiService.insertEntryTicket(
          deviceId: ticket.deviceId,
          plate: ticket.plate,
          ticketNumber: ticket.ticketNumber,
          // token: token,
          entrySyncTime: entrySyncTime, // ← fixed: was hardcoded ''
        )) {
          needsInsert = false;
        }
      }

      if (!needsInsert && needsImage && hasImage) {
        if (await TicketApiService.updateEntryTicketImage(
          deviceId: ticket.deviceId,
          ticketNumber: ticket.ticketNumber,
          base64Image: ticket.base64Image!,
          // token: token,
        )) {
          needsImage = false;
        }
      }

      if (!needsInsert && !needsImage) {
        await PendingTicketDb.delete(ticket.id!);
        await LogHelper.log(
            'OUTBOX', 'Ticket ${ticket.ticketNumber} synced — removed from queue');
      } else {
        await PendingTicketDb.update(ticket.copyWith(
          needsInsert: needsInsert,
          needsImage: needsImage,
          attempts: ticket.attempts + 1,
          lastError: 'Server rejected or partial sync',
        ));
        await LogHelper.log(
            'OUTBOX',
            'Ticket ${ticket.ticketNumber} still pending '
                '(insert=$needsInsert image=$needsImage), attempts=${ticket.attempts + 1}');
      }
    } catch (e, stackTrace) {
      await PendingTicketDb.update(ticket.copyWith(
        needsInsert: needsInsert,
        needsImage: needsImage,
        attempts: ticket.attempts + 1,
        lastError: e.toString(),
      ));
      await LogHelper.logException(
          'Outbox retry failed for ticket ${ticket.ticketNumber}', e, stackTrace);
    }
  }
}