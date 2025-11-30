import 'package:did/services/settings_service.dart';

class ReportFormat {
  String dailyReportFormat(String report) {
    final settings = SettingsService();
    String prefix = settings.dailyHeader;
    String suffix = settings.dailyFooter;

    return prefix + report + suffix;
  }
}
