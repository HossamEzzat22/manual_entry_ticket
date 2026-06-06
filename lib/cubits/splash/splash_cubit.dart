import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';

import '../../services/log_helper/log_helper.dart';
import '../../services/sp_helper/sp_helper.dart';
import '../../services/sp_helper/sp_keys.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> startSplashDelay() async {
    emit(SplashLoading());

    // Run splash delay and old log cleanup in parallel
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      LogHelper.deleteOldLogs(),
    ]);

    // Check if a valid non-expired token exists
    final isValid = await _hasValidSession();

    if (isValid) {
      emit(SplashSessionValid()); // → go directly to entry ticket screen
    } else {
      emit(SplashLoaded()); // → go to login screen
    }
  }

  Future<bool> _hasValidSession() async {
    try {
      final token = SharedPreferenceHelper.getData(
        key: SharedPreferencesKeys.token,
      ) as String? ??
          '';

      if (token.isEmpty) {
        await LogHelper.log('AUTH', 'Splash: no token found → redirect to login');
        return false;
      }

      final expiryStr = SharedPreferenceHelper.getData(
        key: SharedPreferencesKeys.tokenExpiryDate,
      ) as String? ??
          '';

      if (expiryStr.isEmpty) {
        await LogHelper.log('AUTH', 'Splash: no expiry date found → redirect to login');
        return false;
      }

      // Backend format: "06/06/2026 07:01"
      final expiry = DateFormat('dd/MM/yyyy HH:mm').parse(expiryStr);
      final now = DateTime.now();

      if (now.isBefore(expiry)) {
        await LogHelper.log(
          'AUTH',
          'Splash: session valid — expires at $expiryStr → skip login',
        );
        return true;
      } else {
        await LogHelper.log(
          'AUTH',
          'Splash: token expired at $expiryStr → redirect to login',
        );
        // Clear stored credentials so login starts fresh
        await _clearSession();
        return false;
      }
    } catch (e) {
      await LogHelper.log('AUTH', 'Splash: session check error: $e → redirect to login');
      return false;
    }
  }

  Future<void> _clearSession() async {
    await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.token);
    await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.tokenExpiryDate);
    await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.refreshToken);
    await SharedPreferenceHelper.removeData(key: SharedPreferencesKeys.refreshTokenExpiryDate);
  }
}