import 'package:flutter/material.dart';
import 'my_app.dart';
import 'core/network/dio_helper.dart';
import 'services/sp_helper/sp_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local preferences and network helper
  await SharedPreferenceHelper.init();
  DioHelper.init();
  
  runApp(const MyApp());
}
