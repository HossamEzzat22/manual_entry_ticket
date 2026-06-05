class LoginApiResponse {
  final String message;
  final int messageCode;
  final bool success;
  final AuthData data;

  LoginApiResponse({
    required this.message,
    required this.messageCode,
    required this.success,
    required this.data,
  });

  factory LoginApiResponse.fromJson(Map<String, dynamic> json) {
    return LoginApiResponse(
      message: json['message'] as String? ?? '',
      messageCode: json['messageCode'] as int? ?? 0,
      success: json['success'] as bool? ?? false,
      data: AuthData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class AuthData {
  final String token;
  final String role;
  final AuthUser user;

  AuthData({
    required this.token,
    required this.role,
    required this.user,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      token: json['token'] as String? ?? '',
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

  AuthDevice({
    required this.id,
    required this.deviceName,
  });

  factory AuthDevice.fromJson(Map<String, dynamic> json) {
    return AuthDevice(
      id: json['id'] as int? ?? 0,
      deviceName: json['deviceName'] as String? ?? '',
    );
  }
}