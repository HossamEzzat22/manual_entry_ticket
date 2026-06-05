import 'package:bloc/bloc.dart';

import '../../services/log_helper/log_helper.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> startSplashDelay() async {
    emit(SplashLoading());

    // Run splash delay and old log cleanup in parallel
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      LogHelper.deleteOldLogs(),
    ]);

    emit(SplashLoaded());
  }
}