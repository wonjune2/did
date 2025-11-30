import 'package:did/database/app_database.dart';
import 'package:did/screens/main_screen.dart';
import 'package:did/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

late AppDatabase db;

void main() async {
  // Added async keyword
  WidgetsFlutterBinding.ensureInitialized();

  // DB 초기화
  db = AppDatabase();

  // 설정 초기화
  await SettingsService().init();

  runApp(
    const MainApp(),
  ); // Kept MainApp as MyApp is not defined in the provided context
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Did',
      // 1 한국어 로케일 지원 설정
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [Locale('ko', 'KR')],
      home: MainScreen(),
    );
  }
}
