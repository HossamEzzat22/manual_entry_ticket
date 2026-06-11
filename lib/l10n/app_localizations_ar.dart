// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appNameEn => 'التنفيذي';

  @override
  String get parkAssistTagline => 'إدارة مواقف متميزة';

  @override
  String get poweredBy => 'مدعوم من';

  @override
  String get unifiAccess => 'UnifiAccess';

  @override
  String get parking => 'مواقف';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get accessPortal => 'الوصول إلى بوابة الكاشير اليدوي';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailHint => 'example@domain.com';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get emailInvalid =>
      'أدخل بريدًا إلكترونيًا صحيحًا (مثال: example@domain.com)';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get loginButton => 'دخول';

  @override
  String get enterEmailPassword => 'يرجى إدخال البريد الإلكتروني وكلمة المرور';

  @override
  String get notAuthorizedCashier =>
      'حسابك غير مخول ككاشير يدوي. يرجى التواصل مع المسؤول.';

  @override
  String get noRegisteredDevices =>
      'لا يوجد جهاز مسجل لهذا الحساب. يرجى التواصل مع المسؤول.';

  @override
  String get incorrectEmailPassword =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get accountInactive =>
      'الحساب غير موجود أو غير نشط. يرجى التواصل مع المسؤول.';

  @override
  String get serverError =>
      'حدث خطأ في السيرفر. حاول مرة أخرى لاحقًا أو تواصل مع الدعم.';

  @override
  String get loginFailed => 'فشل تسجيل الدخول. حاول مرة أخرى.';

  @override
  String get sessionExpired => 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get accessDenied => 'تم رفض الوصول. غير مصرح لك باستخدام التطبيق.';

  @override
  String get serverNotFound => 'لا يمكن الوصول إلى السيرفر. تحقق من الاتصال.';

  @override
  String get noInternet => 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة.';

  @override
  String get loginErrorGeneric => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get shareLogs => 'مشاركة السجلات';

  @override
  String get authenticating => 'جارٍ المصادقة...';

  @override
  String welcomeBack(String name) {
    return 'مرحباً بعودتك، $name!';
  }

  @override
  String get manualTicketEntry => 'إدخال تذكرة يدوي';

  @override
  String get automaticAi => 'الذكاء الاصطناعي التلقائي';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get capturedPhoto => 'الصورة الملتقطة';

  @override
  String get noPhotoCaptured => 'لم يتم التقاط صورة';

  @override
  String get aiPlateDetectionResult => 'نتيجة كشف اللوحة بالذكاء الاصطناعي';

  @override
  String get plateDetectionResult => 'نتيجة كشف اللوحة';

  @override
  String get detectingPlate => 'جارٍ كشف اللوحة...';

  @override
  String get plateCropPending => 'في انتظار قص اللوحة';

  @override
  String get cameraCaptureCanceled => 'تم إلغاء التقاط الصورة';

  @override
  String get failedToProcessPhoto => 'فشل في معالجة الصورة الملتقطة';

  @override
  String get plateDetectionFailed =>
      'فشل في اكتشاف اللوحة — يرجى إدخال اللوحة يدويًا';

  @override
  String get plateDetectionError =>
      'لم يتم اكتشاف لوحة في هذه الصورة، يرجى التقاط صورة أوضح أو إدخال الرقم يدويًا';

  @override
  String get ocrPlateNotReadable => 'تعذر قراءة اللوحة — يرجى إدخالها يدويًا';

  @override
  String get plateNumber => 'رقم اللوحة';

  @override
  String get digitsLabel => 'الأرقام (بحد أقصى 4)';

  @override
  String get digitsHint => '1234';

  @override
  String get lettersLabel => 'الحروف السعودية (بحد أقصى 3)';

  @override
  String get lettersHint => 'ر س د';

  @override
  String get allowedLetters =>
      'الحروف المسموح بها: A, B, D, E, G, H, J, K, L, N, R, S, T, U, V, W, X, Z';

  @override
  String get submitEntryTicket => 'إرسال تذكرة الدخول';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutTitle => 'تسجيل الخروج';

  @override
  String get logoutMessage => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get cannotLogoutYet => 'لا يمكن تسجيل الخروج الآن';

  @override
  String get pendingTicketsMessage =>
      'يوجد تذاكر غير مرسلة. يرجى التأكد من الاتصال بالإنترنت. نحاول مزامنتها في الخلفية.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get ok => 'حسناً';

  @override
  String get required => 'مطلوب';

  @override
  String get cannotStartWithZero => 'لا يمكن أن يبدأ بالصفر';

  @override
  String get mustBeExactly3Letters => 'يجب أن يكون 3 أحرف بالضبط';

  @override
  String get photoRequired => 'صورة المركبة مطلوبة. يرجى التقاط صورة أولاً.';

  @override
  String get submittingTicket => 'جارٍ إرسال تذكرة الدخول...';

  @override
  String submissionFailed(String error) {
    return 'فشل الإرسال: $error';
  }

  @override
  String captureFailure(String error) {
    return 'فشل الالتقاط: $error';
  }

  @override
  String get aiOcrLoading => 'الذكاء الاصطناعي: جارٍ استخراج بيانات اللوحة...';

  @override
  String get aiOcrSuccess =>
      'اكتشاف تلقائي: تم ملء رقم اللوحة! \n يرجى المراجعة والتصحيح إذا لزم الأمر.';

  @override
  String get ticketInsertedSuccess => 'تم إدراج التذكرة بنجاح';

  @override
  String get closingAutomatically => 'جارٍ الإغلاق تلقائيًا…';

  @override
  String get logFiles => 'ملفات السجل';

  @override
  String get noLogFilesFound => 'لا توجد ملفات سجل';

  @override
  String get today => 'اليوم';

  @override
  String failedToShare(String error) {
    return 'فشل المشاركة: $error';
  }

  @override
  String get changeLanguage => 'English';

  @override
  String get languageCode => 'ar';
}
