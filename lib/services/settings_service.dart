import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Keys
  static const String _keyDailyHeader = 'daily_report_header';
  static const String _keyDailyFooter = 'daily_report_footer';
  static const String _keyWeeklyHeader = 'weekly_report_header';
  static const String _keyWeeklyFooter = 'weekly_report_footer';

  // Defaults
  static const String _defaultDailyHeader = "안녕하세요. ";
  static const String _defaultDailyFooter = " 진행합니다.";
  static const String _defaultWeeklyHeader = "[주간 업무 보고]";
  static const String _defaultWeeklyFooter = "";

  // Getters
  String get dailyHeader =>
      _prefs.getString(_keyDailyHeader) ?? _defaultDailyHeader;
  String get dailyFooter =>
      _prefs.getString(_keyDailyFooter) ?? _defaultDailyFooter;
  String get weeklyHeader =>
      _prefs.getString(_keyWeeklyHeader) ?? _defaultWeeklyHeader;
  String get weeklyFooter =>
      _prefs.getString(_keyWeeklyFooter) ?? _defaultWeeklyFooter;

  // Setters
  Future<void> setDailyHeader(String value) =>
      _prefs.setString(_keyDailyHeader, value);
  Future<void> setDailyFooter(String value) =>
      _prefs.setString(_keyDailyFooter, value);
  Future<void> setWeeklyHeader(String value) =>
      _prefs.setString(_keyWeeklyHeader, value);
  Future<void> setWeeklyFooter(String value) =>
      _prefs.setString(_keyWeeklyFooter, value);
}
