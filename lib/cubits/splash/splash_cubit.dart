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

    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      LogHelper.deleteOldLogs(),
    ]);

    final isValid = await _hasValidSession();

    if (isValid) {
      emit(SplashSessionValid()); // → go directly to entry ticket screen
    } else {
      emit(SplashLoaded()); // → go to login screen
    }
  }

  /// Returns true if the user has a usable session:
  ///  - token still valid (within 4 hours)  → use token
  ///  - token expired but refresh token still valid (within 6 hours) → use refresh token
  ///  - both expired → clear session, go to login
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

      final now = DateTime.now();
      final fmt = DateFormat('dd/MM/yyyy HH:mm');

      // ── Check primary token ──────────────────────────────────────────────
      final tokenExpiryStr = SharedPreferenceHelper.getData(
        key: SharedPreferencesKeys.tokenExpiryDate,
      ) as String? ??
          '';

      if (tokenExpiryStr.isNotEmpty) {
        final tokenExpiry = fmt.parse(tokenExpiryStr);
        if (now.isBefore(tokenExpiry)) {
          await LogHelper.log(
            'AUTH',
            'Splash: token valid — expires at $tokenExpiryStr → skip login',
          );
          return true;
        }
      }

      // ── Primary token expired — check refresh token ──────────────────────
      final refreshToken = SharedPreferenceHelper.getData(
        key: SharedPreferencesKeys.refreshToken,
      ) as String? ??
          '';

      final refreshExpiryStr = SharedPreferenceHelper.getData(
        key: SharedPreferencesKeys.refreshTokenExpiryDate,
      ) as String? ??
          '';

      if (refreshToken.isNotEmpty && refreshExpiryStr.isNotEmpty) {
        final refreshExpiry = fmt.parse(refreshExpiryStr);
        if (now.isBefore(refreshExpiry)) {
          await LogHelper.log(
            'AUTH',
            'Splash: primary token expired but refresh token valid '
                'until $refreshExpiryStr → skip login, DioHelper will use refresh token',
          );
          return true; // refresh token still good — DioHelper will pick it up
        }
      }

      // ── Both expired ─────────────────────────────────────────────────────
      await LogHelper.log(
        'AUTH',
        'Splash: both token and refresh token expired → clear session, redirect to login',
      );
      await _clearSession();
      return false;
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