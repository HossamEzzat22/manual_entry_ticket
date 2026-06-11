import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appNameEn.
  ///
  /// In en, this message translates to:
  /// **'ALTANFEETHI'**
  String get appNameEn;

  /// No description provided for @parkAssistTagline.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM PARKING MANAGEMENT'**
  String get parkAssistTagline;

  /// No description provided for @poweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by'**
  String get poweredBy;

  /// No description provided for @unifiAccess.
  ///
  /// In en, this message translates to:
  /// **'UnifiAccess'**
  String get unifiAccess;

  /// No description provided for @parking.
  ///
  /// In en, this message translates to:
  /// **'PARKING'**
  String get parking;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @accessPortal.
  ///
  /// In en, this message translates to:
  /// **'Access the manual cashier portal'**
  String get accessPortal;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'example@domain.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email (e.g. example@domain.com)'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get passwordHint;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get loginButton;

  /// No description provided for @enterEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email and password.'**
  String get enterEmailPassword;

  /// No description provided for @notAuthorizedCashier.
  ///
  /// In en, this message translates to:
  /// **'Your account is not authorized as a Manual Cashier. Please contact your administrator.'**
  String get notAuthorizedCashier;

  /// No description provided for @noRegisteredDevices.
  ///
  /// In en, this message translates to:
  /// **'No device is registered to your account. Please contact your administrator.'**
  String get noRegisteredDevices;

  /// No description provided for @incorrectEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get incorrectEmailPassword;

  /// No description provided for @accountInactive.
  ///
  /// In en, this message translates to:
  /// **'Your account was not found or is inactive. Please contact your administrator.'**
  String get accountInactive;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later or contact support.'**
  String get serverError;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied. You are not authorized to use this app.'**
  String get accessDenied;

  /// No description provided for @serverNotFound.
  ///
  /// In en, this message translates to:
  /// **'Server not found. Please check your connection.'**
  String get serverNotFound;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get noInternet;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get loginErrorGeneric;

  /// No description provided for @shareLogs.
  ///
  /// In en, this message translates to:
  /// **'SHARE LOGS'**
  String get shareLogs;

  /// No description provided for @authenticating.
  ///
  /// In en, this message translates to:
  /// **'Authenticating...'**
  String get authenticating;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String welcomeBack(String name);

  /// No description provided for @manualTicketEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Ticket Entry'**
  String get manualTicketEntry;

  /// No description provided for @automaticAi.
  ///
  /// In en, this message translates to:
  /// **'Automatic AI'**
  String get automaticAi;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'TAKE PHOTO'**
  String get takePhoto;

  /// No description provided for @capturedPhoto.
  ///
  /// In en, this message translates to:
  /// **'Captured Photo'**
  String get capturedPhoto;

  /// No description provided for @noPhotoCaptured.
  ///
  /// In en, this message translates to:
  /// **'No photo captured'**
  String get noPhotoCaptured;

  /// No description provided for @aiPlateDetectionResult.
  ///
  /// In en, this message translates to:
  /// **'AI Plate Detection Result'**
  String get aiPlateDetectionResult;

  /// No description provided for @plateDetectionResult.
  ///
  /// In en, this message translates to:
  /// **'Plate Detection Result'**
  String get plateDetectionResult;

  /// No description provided for @detectingPlate.
  ///
  /// In en, this message translates to:
  /// **'Detecting plate...'**
  String get detectingPlate;

  /// No description provided for @plateCropPending.
  ///
  /// In en, this message translates to:
  /// **'Plate crop pending'**
  String get plateCropPending;

  /// No description provided for @cameraCaptureCanceled.
  ///
  /// In en, this message translates to:
  /// **'Camera capture canceled'**
  String get cameraCaptureCanceled;

  /// No description provided for @failedToProcessPhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to process captured photo'**
  String get failedToProcessPhoto;

  /// No description provided for @plateDetectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Plate detection failed — please enter the plate manually.'**
  String get plateDetectionFailed;

  /// No description provided for @plateDetectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not detect a plate in this photo. Please take a clearer photo or enter it manually.'**
  String get plateDetectionError;

  /// No description provided for @ocrPlateNotReadable.
  ///
  /// In en, this message translates to:
  /// **'Could not read the plate — please enter it manually.'**
  String get ocrPlateNotReadable;

  /// No description provided for @plateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate Number'**
  String get plateNumber;

  /// No description provided for @digitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Digits (Max 4)'**
  String get digitsLabel;

  /// No description provided for @digitsHint.
  ///
  /// In en, this message translates to:
  /// **'1234'**
  String get digitsHint;

  /// No description provided for @lettersLabel.
  ///
  /// In en, this message translates to:
  /// **'Saudi Letters (Max 3)'**
  String get lettersLabel;

  /// No description provided for @lettersHint.
  ///
  /// In en, this message translates to:
  /// **'RSD'**
  String get lettersHint;

  /// No description provided for @allowedLetters.
  ///
  /// In en, this message translates to:
  /// **'Allowed Letters: A, B, D, E, G, H, J, K, L, N, R, S, T, U, V, W, X, Z'**
  String get allowedLetters;

  /// No description provided for @submitEntryTicket.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT ENTRY TICKET'**
  String get submitEntryTicket;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'LOGOUT'**
  String get logout;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutMessage;

  /// No description provided for @cannotLogoutYet.
  ///
  /// In en, this message translates to:
  /// **'Cannot Logout Yet'**
  String get cannotLogoutYet;

  /// No description provided for @pendingTicketsMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsynced ticket(s). Please check your internet connection. We are trying to sync them in the background.'**
  String get pendingTicketsMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @cannotStartWithZero.
  ///
  /// In en, this message translates to:
  /// **'Cannot start with 0'**
  String get cannotStartWithZero;

  /// No description provided for @mustBeExactly3Letters.
  ///
  /// In en, this message translates to:
  /// **'Must be exactly 3 letters'**
  String get mustBeExactly3Letters;

  /// No description provided for @photoRequired.
  ///
  /// In en, this message translates to:
  /// **'Vehicle photo is required. Please capture a photo first.'**
  String get photoRequired;

  /// No description provided for @submittingTicket.
  ///
  /// In en, this message translates to:
  /// **'Submitting Entry Ticket...'**
  String get submittingTicket;

  /// No description provided for @submissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed: {error}'**
  String submissionFailed(String error);

  /// No description provided for @captureFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture: {error}'**
  String captureFailure(String error);

  /// No description provided for @aiOcrLoading.
  ///
  /// In en, this message translates to:
  /// **'AI OCR: Extracting plate details...'**
  String get aiOcrLoading;

  /// No description provided for @aiOcrSuccess.
  ///
  /// In en, this message translates to:
  /// **'AI Auto-detection: License plate populated! \n Please review and correct if needed.'**
  String get aiOcrSuccess;

  /// No description provided for @ticketInsertedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ticket inserted successfully'**
  String get ticketInsertedSuccess;

  /// No description provided for @closingAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Closing automatically…'**
  String get closingAutomatically;

  /// No description provided for @logFiles.
  ///
  /// In en, this message translates to:
  /// **'Log Files'**
  String get logFiles;

  /// No description provided for @noLogFilesFound.
  ///
  /// In en, this message translates to:
  /// **'No log files found'**
  String get noLogFilesFound;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @failedToShare.
  ///
  /// In en, this message translates to:
  /// **'Failed to share: {error}'**
  String failedToShare(String error);

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get changeLanguage;

  /// No description provided for @languageCode.
  ///
  /// In en, this message translates to:
  /// **'en'**
  String get languageCode;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
