import 'package:did/database/app_database.dart';
import 'package:did/screens/main_screen.dart';
import 'package:flutter/material.dart';

late AppDatabase db;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // DB 초기화
  db = AppDatabase();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Did', home: MainScreen());
  }
}
