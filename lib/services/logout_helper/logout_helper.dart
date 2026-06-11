import 'package:flutter/material.dart';
import 'package:manual_entry_ticket/l10n/app_localizations.dart';

import '../log_helper/log_helper.dart';
import '../pending_ticket/pending_ticket_db.dart';
import '../pending_ticket/pending_ticket_retry_service.dart';
import '../sp_helper/sp_helper.dart';
import '../sp_helper/sp_keys.dart';

abstract class LogoutHelper {
  static Future<void> logout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    await LogHelper.log('AUTH', 'Logout dialog shown to user');

    // ── Guard: block logout if there are unsynced tickets ─────────────────
    final pending = await PendingTicketDb.getAll();
    if (pending.isNotEmpty) {
      await LogHelper.log(
        'AUTH',
        'Logout blocked — ${pending.length} unsynced ticket(s) in queue, triggering retry flush',
      );

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.cannotLogoutYet),
            content: Text(l10n.pendingTicketsMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }

      // Trigger an immediate retry in the background
      PendingTicketRetryService.instance.flush();
      return;
    }

    // ── Confirmation dialog ───────────────────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.logout,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      await LogHelper.log('AUTH', 'Logout cancelled by user');
      return;
    }

    if (!context.mounted) return;

    await LogHelper.log('AUTH', 'Logout confirmed — clearing all session data');

    try {
      await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.token);
      await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.tokenExpiryDate);
      await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.refreshToken);
      await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.refreshTokenExpiryDate);
      await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.userRoles);
      await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.userId);
      await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.clientId);
      await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.facilityId);
      await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.userName);
      await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.username);
      await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.deviceID);
      await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.deviceName);
      await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.carParkId);

      await LogHelper.log(
        'AUTH',
        'All session data cleared successfully — navigating to login',
      );
    } catch (e, stackTrace) {
      await LogHelper.logException(
        'Failed to clear session data during logout',
        e,
        stackTrace,
      );
    }

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login_screen',
            (route) => false,
      );
    }
  }
}