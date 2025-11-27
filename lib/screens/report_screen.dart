import 'package:did/database/app_database.dart';
import 'package:did/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final now = DateTime.now();

  late final today = DateTime(now.year, now.month, now.day);

  // 이번 주 월요일
  late final DateTime startOfWeek = today.subtract(Duration(days: now.weekday - 1));

  // 이번 주 금요일 (월요일 + 4일)
  late final DateTime endOfWeekFriday = startOfWeek.add(
    const Duration(days: 4, hours: 23, minutes: 59, seconds: 59),
  );

  late DateTimeRange _selectedDateRange = DateTimeRange(start: startOfWeek, end: endOfWeekFriday);

  // 날짜 선택 팝업 띄우기
  Future<void> _pickDateRange() async {
    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
    );

    if (newRange != null) {
      setState(() {
        _selectedDateRange = newRange;
      });
    }
  }

  // 클립보드 복사(데이터를 인자로 받아서 처리)
  void _copyToClipboard(List<Task> tasks) {
    if (tasks.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('[주간 업무 보고]');
    buffer.writeln(
      '기간: ${DateFormat('yyyy-MM-dd').format(_selectedDateRange.start)} ~ ${DateFormat('yyyy-MM-dd').format(_selectedDateRange.end)}',
    );
    buffer.writeln();

    for (var task in tasks) {
      final dateStr = DateFormat('MM/dd').format(task.completeAt!);
      buffer.writeln('- ${task.title} ($dateStr 완료)');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));

    // 사용자에게 알려주기
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('업무 목록이 클립보드에 복사되었습니다!!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: db.watchCompletedTasksByDate(_selectedDateRange.start, _selectedDateRange.end),
        builder: (context, snapshot) {
          // 1, 로딩 중일 때
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!;

          // 2. 데이터가 다 로드된 후 UI 그리기
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('보고 기간: ', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        '${DateFormat('yyyy-MM-dd').format(_selectedDateRange.start)} ~ ${DateFormat('yyyy-MM-dd').format(_selectedDateRange.end)}',
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: tasks.isEmpty ? null : () => _copyToClipboard(tasks),
                      label: const Text('텍스트 복사하기'),
                      icon: const Icon(Icons.copy),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // 결과 리스트 보여주기
                Expanded(
                  child: tasks.isEmpty
                      ? const Center(child: Text('선택한 기간에 완료된 업무가 없습니다.'))
                      : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return ListTile(
                              leading: const Icon(Icons.check_circle, color: Colors.green),
                              title: Text(task.title),
                              subtitle: Text(
                                '완료일: ${DateFormat('yyyy-MM-dd HH:mm').format(task.completeAt!)}',
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
