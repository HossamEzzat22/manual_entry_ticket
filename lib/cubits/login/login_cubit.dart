import 'dart:convert';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:manual_entry_ticket/l10n/app_localizations.dart';
import 'package:manual_entry_ticket/services/log_helper/log_helper.dart';
import 'package:dio/dio.dart';

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



  Future<void> login(AppLocalizations l10n) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      emit(LoginError(message: l10n.enterEmailPassword));
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
        data: {"email": email, "password": password},
      );

      loginResponse = LoginApiResponse.fromJson(response.data);

      if (!loginResponse!.success) {
        final serverMsg = loginResponse!.message.trim();
        final userMsg = _mapServerMessage(serverMsg, l10n);

        await LogHelper.log('AUTH', 'Login rejected by server: $serverMsg');
        emit(LoginError(message: userMsg));
        return;
      }

      final data = loginResponse!.data!;

      if (data.role != 'Cashier') {
        await LogHelper.log('AUTH', 'Login rejected — role: ${data.role}');
        emit(LoginError(message: l10n.accessDenied));
        return;
      }

      final user = data.user;

      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.token, value: data.token);
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.tokenExpiryDate, value: data.tokenExpiryDate);
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.refreshToken, value: data.refreshToken);
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.refreshTokenExpiryDate, value: data.refreshTokenExpiryDate);
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
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.carParkId,
          value: user.device?.carParkId.toString() ?? '');

      await LogHelper.log('AUTH', 'Login success — user: ${user.name}');

      emit(LoginSuccess(
        userId: user.userId.toString(),
        userName: user.name,
        role: data.role,
        carParkId: user.device?.carParkId.toString() ?? '',
      ));
    } on DioException catch (e, stackTrace) {
      await LogHelper.logException('Login request failed', e, stackTrace);

      final statusCode = e.response?.statusCode;

      final userMsg = _mapHttpError(statusCode, l10n);

      emit(LoginError(message: userMsg));
    } catch (e, stackTrace) {
      await LogHelper.logException('Login unexpected error', e, stackTrace);
      emit(LoginError(message: l10n.loginErrorGeneric));
    }
  }

  // ── mapping server messages ──
  String _mapServerMessage(String msg, AppLocalizations l10n)  {
    switch (msg) {
      case 'Failed To Login Because Not Manual Cashier':
        return l10n.notAuthorizedCashier;
      case 'Failed To Login Because No Registered Devices':
        return l10n.noRegisteredDevices;
      case 'Failed To Login InCorrect Email Or Password':
        return l10n.incorrectEmailPassword;
      case 'Email Or Password is not correct':
        return l10n.incorrectEmailPassword;
      case 'Device is not Registered or InActive':
        return l10n.accountInactive;
      case 'Failed':
        return l10n.serverError;
      default:
        LogHelper.log('AUTH', 'UNMAPPED_SERVER_MSG: "$msg"');
        return msg.isNotEmpty ? msg : l10n.loginFailed;
    }
  }

  // ── HTTP errors ──
  String _mapHttpError(int? statusCode, AppLocalizations l10n) {
    switch (statusCode) {
      case 400:
        return l10n.incorrectEmailPassword;
      case 401:
        return l10n.sessionExpired;
      case 403:
        return l10n.accessDenied;
      case 404:
        return l10n.serverNotFound;
      case 500:
        return l10n.serverError;
      case null:
        return l10n.noInternet;
      default:
        return "${l10n.loginFailed} ($statusCode)";
    }
  }

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}