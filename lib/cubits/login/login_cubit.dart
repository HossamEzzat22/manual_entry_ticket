import 'dart:convert';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
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

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      emit(LoginError(message: "Please enter your email and password."));
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
        final userMsg = _mapServerMessage(serverMsg);
        await LogHelper.log('AUTH', 'Login rejected by server: $serverMsg');
        emit(LoginError(message: userMsg));
        return;
      }

      // data is guaranteed non-null when success=true
      final data = loginResponse!.data!;

      if (data.role != 'Cashier') {
        const errorMsg = "Access denied. Only Cashier accounts can use this app.";
        await LogHelper.log('AUTH', 'Login rejected — role: ${data.role}');
        emit(LoginError(message: errorMsg));
        return;
      }

      final user = data.user;

      // ── Persist all response data ──────────────────────────────────────
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
      // ← new: store carParkId so ticket generation can use it anywhere
      await SharedPreferenceHelper.saveData(
          key: SharedPreferencesKeys.carParkId,
          value: user.device?.carParkId.toString() ?? '');

      await LogHelper.log(
        'AUTH',
        'Login success — user: ${user.name} (${user.email}), '
            'role: ${data.role}, facilityId: ${user.facilityId}, '
            'deviceId: ${user.device?.id}, deviceName: ${user.device?.deviceName}, '
            'carParkId: ${user.device?.carParkId}',
      );

      emit(LoginSuccess(
        userId: user.userId.toString(),
        userName: user.name,
        role: data.role,
        carParkId: user.device?.carParkId.toString() ?? '',
      ));

    } on DioException catch (e, stackTrace) {
      await LogHelper.logException('Login request failed', e, stackTrace);

      final statusCode = e.response?.statusCode;

      String? rawMsg;
      try {
        final responseData = e.response?.data;
        if (responseData is Map) {
          rawMsg = responseData['message'] as String?;
        } else if (responseData is String && responseData.isNotEmpty) {
          final decoded = jsonDecode(responseData);
          if (decoded is Map) rawMsg = decoded['message'] as String?;
        }
      } catch (_) {}

      await LogHelper.log(
          'AUTH', 'Login HTTP error — status: $statusCode, rawMsg: $rawMsg');

      final userMsg = rawMsg != null && rawMsg.trim().isNotEmpty
          ? _mapServerMessage(rawMsg.trim())
          : _mapHttpError(statusCode);

      emit(LoginError(message: userMsg));

    } catch (e, stackTrace) {
      await LogHelper.logException('Login unexpected error', e, stackTrace);
      emit(LoginError(message: "Something went wrong. Please try again."));
    }
  }

  // ── Ticket number generation ─────────────────────────────────────────────
  // Mirrors the C# backend logic exactly:
  // format: {ticketType}{HH}{r[0]}{mm}{r[1]}{dd}{r[2]}{MM}{second[0]}{yy}{second[1]}{01}{carParkId}
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

    return "$ticketType$hh${r[0]}$mm${r[1]}$dd${r[2]}$MM${second[0]}$yy${second[1]}$constVal$carParkId";
  }

  // Convenience: reads carParkId from SharedPreferences and generates ticket
  Future<String> generateTicketNumberFromStorage() async {
    final carParkId = SharedPreferenceHelper.getData(
      key: SharedPreferencesKeys.carParkId,
    ) as String? ??
        '';
    if (carParkId.isEmpty) {
      await LogHelper.log('TICKET', 'WARNING: carParkId is empty — ticket number may be invalid');
    }
    final ticket = generateTicketNumber(carParkId);
    await LogHelper.log('TICKET', 'Generated ticket number: $ticket (carParkId: $carParkId)');
    return ticket;
  }

  // ── Message mappers ──────────────────────────────────────────────────────
  String _mapServerMessage(String serverMsg) {
    switch (serverMsg) {
      case 'Failed To Login Because Not Manual Cashier':
        return "Your account is not authorized as a Manual Cashier. Please contact your administrator.";
      case 'Failed To Login Because No Registered Devices':
        return "No device is registered to your account. Please contact your administrator.";
      case 'Failed To Login InCorrect Email Or Password':
        return "Incorrect email or password. Please try again.";
      case 'Device is not Registered or InActive':
        return "Your account was not found or is inactive. Please contact your administrator.";
      case 'Failed':
        return "Server error. Please try again later or contact support.";
      default:
        return serverMsg.isNotEmpty ? serverMsg : "Login failed. Please try again.";
    }
  }

  String _mapHttpError(int? statusCode) {
    switch (statusCode) {
      case 400:
        return "Incorrect email or password. Please try again.";
      case 401:
        return "Session expired. Please log in again.";
      case 403:
        return "Access denied. You are not authorized to use this app.";
      case 404:
        return "Server not found. Please check your connection.";
      case 500:
        return "Server error. Please try again later or contact support.";
      case null:
        return "No internet connection. Please check your network and try again.";
      default:
        return "Login failed (error $statusCode). Please try again.";
    }
  }

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}