import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manual_entry_ticket/services/sp_helper/sp_keys.dart';
import '../../services/sp_helper/sp_helper.dart';

part 'language_state.dart';

class LanguageCubit extends Cubit<LanguageState> {
  static const String _langKey = SharedPreferencesKeys.appLanguage;

  LanguageCubit() : super(const LanguageState(locale: Locale('en'))){
    loadSavedLanguage();
  }

  /// Call this on app start to restore saved language
  Future<void> loadSavedLanguage() async {
    final saved = SharedPreferenceHelper.getData(key: _langKey);

    if (saved != null && saved is String && saved.isNotEmpty) {
      emit(LanguageState(locale: Locale(saved)));
    }
  }



  Future<void> changeLanguage(String languageCode) async {
    await SharedPreferenceHelper.saveData(
      key: _langKey,
      value: languageCode,
    );

    emit(LanguageState(locale: Locale(languageCode)));
  }

  void toggleLanguage() {
    final current = state.locale.languageCode;
    final next = current == 'en' ? 'ar' : 'en';
    changeLanguage(next);
  }
}