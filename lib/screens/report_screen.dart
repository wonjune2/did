import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../main.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    end: DateTime.now(),
  );

  Future<void> _pickDateRange() async {
    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
    );
    if (newRange != null) {
      setState(() => _selectedDateRange = newRange);
    }
  }

  // [수정] 복사 로직: 프로젝트 이름 포함하기
  void _copyToClipboard(List<TaskWithProject> items) {
    final buffer = StringBuffer();
    buffer.writeln("[주간 업무 보고]");
    buffer.writeln(
      "기간: ${DateFormat('yyyy-MM-dd').format(_selectedDateRange.start)} ~ ${DateFormat('yyyy-MM-dd').format(_selectedDateRange.end)}",
    );
    buffer.writeln();

    for (var item in items) {
      final task = item.task;
      final project = item.project;
      final dateStr = DateFormat('MM/dd').format(task.completeAt!);

      // 프로젝트가 있으면 [한미글로벌], 없으면 빈칸
      final projectPrefix = project != null ? "[${project.name}] " : "";

      // 예: - [한미글로벌] 회의록 작성 (05/20 완료)
      buffer.writeln("- $projectPrefix${task.title} ($dateStr 완료)");
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('업무 목록이 클립보드에 복사되었습니다!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [수정] TaskWithProject 사용
      body: StreamBuilder<List<TaskWithProject>>(
        stream: db.watchCompletedTasksWithProjectByDate(
          _selectedDateRange.start,
          _selectedDateRange.end,
        ), // [수정] 새 쿼리
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final items = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 컨트롤 바
                Row(
                  children: [
                    Text(
                      "보고 기간: ",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        "${DateFormat('yyyy-MM-dd').format(_selectedDateRange.start)} ~ ${DateFormat('yyyy-MM-dd').format(_selectedDateRange.end)}",
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: items.isEmpty
                          ? null
                          : () => _copyToClipboard(items),
                      icon: const Icon(Icons.copy),
                      label: const Text("텍스트로 복사하기"),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // 리스트 보여주기
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text("선택한 기간에 완료된 업무가 없습니다."))
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final task = item.task;
                            final project = item.project;

                            return ListTile(
                              leading: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              title: Row(
                                children: [
                                  // [New] 프로젝트 뱃지
                                  if (project != null)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        project.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  Expanded(child: Text(task.title)),
                                ],
                              ),
                              subtitle: Text(
                                "완료일: ${DateFormat('yyyy-MM-dd HH:mm').format(task.completeAt!)}",
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.undo_rounded),
                                onPressed: () => db.toggleTask(task),
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
