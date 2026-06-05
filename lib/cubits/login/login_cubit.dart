import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:manual_entry_ticket/services/log_helper/log_helper.dart';

import '../../core/network/dio_helper.dart';
import '../../models/login_response_model.dart';
import '../../services/sp_helper/sp_helper.dart';
import '../../services/sp_helper/sp_keys.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(LoginInitial());

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  LoginApiResponse? loginResponse;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      emit(LoginError(message: "Email and Password cannot be empty"));
      return;
    }

    emit(LoginLoading());

    await LogHelper.logApiRequest('POST', 'api/User/Login', data: {
      "email": email,
      "password": "[HIDDEN]",
    });

    try {
      final response = await DioHelper.postData(
        url: 'api/User/Login',
        data: {
          "email": email,
          "password": password,
        },
      );

      loginResponse = LoginApiResponse.fromJson(response.data);

      // Reject if API returned success:false
      if (!loginResponse!.success) {
        final errorMsg = loginResponse!.message.isNotEmpty
            ? loginResponse!.message
            : "Login failed. Please check your credentials.";
        await LogHelper.log('AUTH', 'Login rejected by server: $errorMsg');
        emit(LoginError(message: errorMsg));
        return;
      }

      // Reject if role is not Cashier
      if (loginResponse!.data.role != 'Cashier') {
        const errorMsg = "Access denied. Only Cashier accounts can use this app.";
        await LogHelper.log('AUTH', 'Login rejected — role: ${loginResponse!.data.role}');
        emit(LoginError(message: errorMsg));
        return;
      }

      final data = loginResponse!.data;
      final user = data.user;

      // ── Persist all response data to SharedPreferences ──────────────────────
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.token, value: data.token);
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.userRoles, value: data.role);
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.userId, value: user.userId.toString());
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.clientId, value: user.clientId.toString());
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.facilityId, value: user.facilityId.toString());
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.userName, value: user.name);
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.username, value: user.email);
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.deviceID,
          value: user.device?.id.toString() ?? '');
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.deviceName,
          value: user.device?.deviceName ?? '');

      await LogHelper.log(
        'AUTH',
        'Login success — user: ${user.name} (${user.email}), '
            'role: ${data.role}, facilityId: ${user.facilityId}, '
            'deviceId: ${user.device?.id}, deviceName: ${user.device?.deviceName}',
      );

      emit(LoginSuccess(
        userId: user.userId.toString(),
        userName: user.name,
        role: data.role,
      ));
    } catch (e, stackTrace) {
      await LogHelper.logException('Login request failed', e, stackTrace);
      emit(LoginError(message: "Login failed: ${e.toString()}"));
    }
  }

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}