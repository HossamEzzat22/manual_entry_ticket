part of 'login_cubit.dart';

sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {
  final String userId;
  final String userName;
  final String role;
  final String carParkId; // ← new


  LoginSuccess({
    required this.userId,
    required this.userName,
    required this.role,
    required this.carParkId, // ← new

  });
}

final class LoginError extends LoginState {
  final String message;
  LoginError({required this.message});
}