
import 'package:bloc/bloc.dart';
import 'package:manual_entry_ticket/services/log_helper/log_helper.dart';
import '../../services/sp_helper/sp_helper.dart';

part 'app_settings_state.dart';

class AppSettingsCubit extends Cubit<AppSettingsState> {
  // Load initial AI settings state (defaults to true)
  AppSettingsCubit() : super(AppSettingsState(
    isAiAnalysisEnabled: SharedPreferenceHelper.getData(key: 'is_ai_analysis_enabled') as bool? ?? true,
  ));

  // Toggle AI Analysis and save to SharedPreferences
  Future<void> toggleAiAnalysis(bool isEnabled) async {
    await SharedPreferenceHelper.saveData(key: 'is_ai_analysis_enabled', value: isEnabled);
    emit(AppSettingsState(isAiAnalysisEnabled: isEnabled));
    await LogHelper.log('SETTINGS', 'Automatic AI Analysis toggled to: $isEnabled');
  }
}
