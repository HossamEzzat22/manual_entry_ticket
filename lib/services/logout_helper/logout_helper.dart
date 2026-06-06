import 'package:flutter/material.dart';

import '../log_helper/log_helper.dart';
import '../sp_helper/sp_helper.dart';
import '../sp_helper/sp_keys.dart';

abstract class LogoutHelper {
  /// Shows a confirmation dialog, clears all SharedPreferences on confirm,
  /// then navigates to the login screen removing all previous routes.
  static Future<void> logout(BuildContext context) async {
    await LogHelper.log('AUTH', 'Logout dialog shown to user');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
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

      await LogHelper.log('AUTH', 'All session data cleared successfully — navigating to login');
    } catch (e, stackTrace) {
      await LogHelper.logException('Failed to clear session data during logout', e, stackTrace);
    }

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login_screen', (route) => false);
    }
  }
}