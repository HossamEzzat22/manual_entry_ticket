// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appNameEn => 'ALTANFEETHI';

  @override
  String get parkAssistTagline => 'PREMIUM PARKING MANAGEMENT';

  @override
  String get poweredBy => 'Powered by';

  @override
  String get unifiAccess => 'UnifiAccess';

  @override
  String get parking => 'PARKING';

  @override
  String get signIn => 'Sign In';

  @override
  String get accessPortal => 'Access the manual cashier portal';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'example@domain.com';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email (e.g. example@domain.com)';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get loginButton => 'LOGIN';

  @override
  String get enterEmailPassword => 'Please enter your email and password.';

  @override
  String get notAuthorizedCashier =>
      'Your account is not authorized as a Manual Cashier. Please contact your administrator.';

  @override
  String get noRegisteredDevices =>
      'No device is registered to your account. Please contact your administrator.';

  @override
  String get incorrectEmailPassword =>
      'Incorrect email or password. Please try again.';

  @override
  String get accountInactive =>
      'Your account was not found or is inactive. Please contact your administrator.';

  @override
  String get serverError =>
      'Server error. Please try again later or contact support.';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get sessionExpired => 'Session expired. Please log in again.';

  @override
  String get accessDenied =>
      'Access denied. You are not authorized to use this app.';

  @override
  String get serverNotFound =>
      'Server not found. Please check your connection.';

  @override
  String get noInternet =>
      'No internet connection. Please check your network and try again.';

  @override
  String get loginErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get shareLogs => 'SHARE LOGS';

  @override
  String get authenticating => 'Authenticating...';

  @override
  String welcomeBack(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String get manualTicketEntry => 'Manual Ticket Entry';

  @override
  String get automaticAi => 'Automatic AI';

  @override
  String get takePhoto => 'TAKE PHOTO';

  @override
  String get capturedPhoto => 'Captured Photo';

  @override
  String get noPhotoCaptured => 'No photo captured';

  @override
  String get aiPlateDetectionResult => 'AI Plate Detection Result';

  @override
  String get plateDetectionResult => 'Plate Detection Result';

  @override
  String get detectingPlate => 'Detecting plate...';

  @override
  String get plateCropPending => 'Plate crop pending';

  @override
  String get cameraCaptureCanceled => 'Camera capture canceled';

  @override
  String get failedToProcessPhoto => 'Failed to process captured photo';

  @override
  String get plateDetectionFailed =>
      'Plate detection failed — please enter the plate manually.';

  @override
  String get plateDetectionError =>
      'Could not detect a plate in this photo. Please take a clearer photo or enter it manually.';

  @override
  String get ocrPlateNotReadable =>
      'Could not read the plate — please enter it manually.';

  @override
  String get plateNumber => 'Plate Number';

  @override
  String get digitsLabel => 'Digits (Max 4)';

  @override
  String get digitsHint => '1234';

  @override
  String get lettersLabel => 'Saudi Letters (Max 3)';

  @override
  String get lettersHint => 'RSD';

  @override
  String get allowedLetters =>
      'Allowed Letters: A, B, D, E, G, H, J, K, L, N, R, S, T, U, V, W, X, Z';

  @override
  String get submitEntryTicket => 'SUBMIT ENTRY TICKET';

  @override
  String get logout => 'LOGOUT';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get logoutMessage => 'Are you sure you want to logout?';

  @override
  String get cannotLogoutYet => 'Cannot Logout Yet';

  @override
  String get pendingTicketsMessage =>
      'You have unsynced ticket(s). Please check your internet connection. We are trying to sync them in the background.';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get required => 'Required';

  @override
  String get cannotStartWithZero => 'Cannot start with 0';

  @override
  String get mustBeExactly3Letters => 'Must be exactly 3 letters';

  @override
  String get photoRequired =>
      'Vehicle photo is required. Please capture a photo first.';

  @override
  String get submittingTicket => 'Submitting Entry Ticket...';

  @override
  String submissionFailed(String error) {
    return 'Submission failed: $error';
  }

  @override
  String captureFailure(String error) {
    return 'Failed to capture: $error';
  }

  @override
  String get aiOcrLoading => 'AI OCR: Extracting plate details...';

  @override
  String get aiOcrSuccess =>
      'AI Auto-detection: License plate populated! \n Please review and correct if needed.';

  @override
  String get ticketInsertedSuccess => 'Ticket inserted successfully';

  @override
  String get closingAutomatically => 'Closing automatically…';

  @override
  String get logFiles => 'Log Files';

  @override
  String get noLogFilesFound => 'No log files found';

  @override
  String get today => 'Today';

  @override
  String failedToShare(String error) {
    return 'Failed to share: $error';
  }

  @override
  String get changeLanguage => 'العربية';

  @override
  String get languageCode => 'en';
}
