class LoginApiResponse {
  final String message;
  final int messageCode;
  final bool success;
  final AuthData? data;

  LoginApiResponse({
    required this.message,
    required this.messageCode,
    required this.success,
    this.data,
  });

  factory LoginApiResponse.fromJson(Map<String, dynamic> json) {
    return LoginApiResponse(
      message: json['message'] as String? ?? '',
      messageCode: json['messageCode'] as int? ?? 0,
      success: json['success'] as bool? ?? false,
      // data is null when success=false (backend returns null data on errors)
      data: json['data'] != null
          ? AuthData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AuthData {
  final String token;
  final String tokenExpiryDate;
  final String refreshToken;
  final String refreshTokenExpiryDate;
  final String role;
  final AuthUser user;

  AuthData({
    required this.token,
    required this.tokenExpiryDate,
    required this.refreshToken,
    required this.refreshTokenExpiryDate,
    required this.role,
    required this.user,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      token: json['token'] as String? ?? '',
      tokenExpiryDate: json['token_Expiry_Date'] as String? ?? '',
      refreshToken: json['refresh_Token'] as String? ?? '',
      refreshTokenExpiryDate: json['refresh_Token_Expiry_Date'] as String? ?? '',
      role: json['role'] as String? ?? '',
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthUser {
  final int userId;
  final int clientId;
  final int facilityId;
  final String name;
  final String email;
  final String? mobileNumber;
  final bool isActive;
  final AuthDevice? device;

  AuthUser({
    required this.userId,
    required this.clientId,
    required this.facilityId,
    required this.name,
    required this.email,
    this.mobileNumber,
    required this.isActive,
    this.device,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['userId'] as int? ?? 0,
      clientId: json['clientId'] as int? ?? 0,
      facilityId: json['facilityId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      device: json['device'] != null
          ? AuthDevice.fromJson(json['device'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AuthDevice {
  final int id;
  final String deviceName;
  final int carParkId; // ← new field

  AuthDevice({
    required this.id,
    required this.deviceName,
    required this.carParkId,
  });

  factory AuthDevice.fromJson(Map<String, dynamic> json) {
    return AuthDevice(
      id: json['id'] as int? ?? 0,
      deviceName: json['deviceName'] as String? ?? '',
      carParkId: json['carParkId'] as int? ?? 0, // ← new field
    );
  }
}