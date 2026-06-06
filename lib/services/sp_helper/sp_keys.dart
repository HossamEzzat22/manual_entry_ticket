// TODO: Add, remove, or modify preference keys here to align with the real backend storage requirements.
class SharedPreferencesKeys {
  static const String token = 'token';
  static const String userName = 'userName';
  static const String deviceID = 'deviceID';
  static const String deviceName = 'deviceName';
  static const String tokenExpiryDate = 'token_expiry_date';
  static const String refreshToken = 'refresh_token';
  static const String refreshTokenExpiryDate = 'refresh_token_expiry_date';
  static const String carParkId = 'car_park_id';
  static const String expireDateTime = 'expireDateTime';
  static const String expiredRefreshToken = 'expiredRefreshToken';
  static const String userId = 'userId';
  static const String username = 'username';
  static const String userRoles = 'userRoles';

  // Ticket submission & config details
  static const String facilityId = 'facilityId';
  static const String clientId = 'clientId';
  static const String capturedImagePath = 'capturedImagePath';
  
  // Daily logs key
  static const String logs = 'daily_logs';
}