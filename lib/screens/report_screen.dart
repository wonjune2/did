import 'package:flutter/material.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final now = DateTime.now();

  late final today = DateTime(now.year, now.month, now.day);

  // 이번 주 월요일
  late final DateTime startOfWeek = today.subtract(
    Duration(days: now.weekday - 1),
  );

  // 이번 주 금요일 (월요일 + 4일)
  late final DateTime endOfWeekFriday = startOfWeek.add(
    const Duration(days: 4, hours: 23, minutes: 59, seconds: 59),
  );
  late DateTimeRange dateRange = DateTimeRange(
    start: startOfWeek,
    end: endOfWeekFriday,
  );
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
