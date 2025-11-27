import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏆 완료한 업무', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: db.watchCompletedTasks(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final tasks = snapshot.data!;
                  if (tasks.isEmpty) {
                    return const Center(child: Text('아직 완료된 업무가 없습니다.\n오늘 할 일을 끝내보세요!'));
                  }

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text(
                            task.title,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                          subtitle: Text(
                            '완료: ${DateFormat('yyyy-MM-dd').format(task.completeAt!)}',
                          ),
                          trailing: IconButton(
                            onPressed: () => db.toggleTask(task),
                            icon: const Icon(Icons.undo, color: Colors.blue),
                            tooltip: '다시 오늘 할 일로 되돌리기',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
