
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manual_entry_ticket/screens/entry_ticket_screen.dart';
import 'package:manual_entry_ticket/screens/login_screen.dart';
import 'package:manual_entry_ticket/screens/splash_screen.dart' hide SplashCubit;
import 'package:sizer/sizer.dart';

import 'core/utils/navigator_key.dart';
import 'cubits/language/language_cubit.dart';
import 'cubits/splash/splash_cubit.dart';
import 'cubits/login/login_cubit.dart';
import 'cubits/insert_manual_entry_ticket/insert_manual_entry_ticket_cubit.dart';
import 'cubits/upload_image_file/upload_image_file_cubit.dart';
import 'cubits/app_settings/app_settings_cubit.dart';
import 'l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final blocProviders = <BlocProvider<dynamic>>[
      BlocProvider<SplashCubit>(create: (context) => SplashCubit()),
      BlocProvider<LoginCubit>(create: (context) => LoginCubit()),
      BlocProvider<InsertManualEntryTicketCubit>(create: (context) => InsertManualEntryTicketCubit()),
      BlocProvider<UploadImageFileCubit>(create: (context) => UploadImageFileCubit()),
      BlocProvider<AppSettingsCubit>(create: (context) => AppSettingsCubit()),
      BlocProvider<LanguageCubit>(create: (context)  => LanguageCubit()),

    ];

    final appChild = Sizer(
      builder: (context, orientation, deviceType) {
        final locale = context.watch<LanguageCubit>().state.locale;

        return ScreenUtilInit(
                  designSize: const Size(360, 690),
                  minTextAdapt: true,
                  splitScreenMode: true,
                  child: MaterialApp(
        navigatorKey: navigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login_screen': (context) => const LoginScreen(),
          '/entry_ticket_screen': (context) => const EntryTicketScreen(),
        },
        debugShowCheckedModeBanner: false,

        locale: locale,
        supportedLocales: [
          Locale('en'),
          Locale('ar'),
        ],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

                  ),
                )
        ;
      },
    );

    if (blocProviders.isEmpty) return appChild;

    return MultiBlocProvider(
      providers: blocProviders,
      child: appChild,
    );
  }
}