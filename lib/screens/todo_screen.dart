import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/app_database.dart';
import '../main.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _textController = TextEditingController();

  // 현재 선택된 프로젝트 ID (null이면 '프로젝트 없음')
  int? _selectedProjectId;

  // 1. 업무 추가 (선택된 프로젝트 ID 함께 저장)
  void _addTask(String title) {
    if (title.isEmpty) return;
    db.insertTask(title, projectId: _selectedProjectId); // 프로젝트 ID 전달
    _textController.clear();
  }

  // 2. 프로젝트 추가 팝업
  void _showAddProjectDialog() {
    final projectController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("새 프로젝트/고객사 추가"),
        content: TextField(
          controller: projectController,
          decoration: const InputDecoration(hintText: "예: 한미글로벌, 삼성전자"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          FilledButton(
            onPressed: () {
              if (projectController.text.isNotEmpty) {
                db.insertProject(projectController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("추가"),
          ),
        ],
      ),
    );
  }

  void _toggleTask(Task task) => db.toggleTask(task);
  void _deleteTask(int id) => db.deleteTask(id);

  // 복사 로직 (프로젝트 이름도 같이 복사되게 수정!)
  void _copyIncompleteTasks(List<TaskWithProject> items) {
    final incomplete = items.where((i) => !i.task.isCompleted).toList();
    if (incomplete.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln("[진행 중인 업무]");
    for (var item in incomplete) {
      final projectPrefix = item.project != null ? "[${item.project!.name}] " : "";
      buffer.writeln("- $projectPrefix${item.task.title}");
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('복사 완료!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // --- 상단 입력 영역 ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 프로젝트 선택기 (StreamBuilder로 실시간 목록 가져옴)
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Project>>(
                        stream: db.watchAllProjects(),
                        builder: (context, snapshot) {
                          final projects = snapshot.data ?? [];

                          return DropdownButtonFormField<int?>(
                            initialValue: _selectedProjectId,
                            decoration: const InputDecoration(
                              labelText: '프로젝트 선택',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text("프로젝트 없음 (일반)")),
                              ...projects.map(
                                (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedProjectId = value);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 프로젝트 추가 버튼
                    IconButton.outlined(
                      onPressed: _showAddProjectDialog,
                      icon: const Icon(Icons.add_business),
                      tooltip: "새 프로젝트 추가",
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 2. 업무 입력창
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: '업무 내용을 입력하세요 (Enter)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.task_alt),
                        ),
                        onSubmitted: (value) => _addTask(value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () => _addTask(_textController.text),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- 하단 리스트 영역 ---
          Expanded(
            child: StreamBuilder<List<TaskWithProject>>(
              stream: db.watchAllTasksWithProjects(), // 수정된 쿼리 호출
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final items = snapshot.data!;
                final incompleteCount = items.where((i) => !i.task.isCompleted).length;

                if (items.isEmpty) {
                  return const Center(child: Text("업무가 없습니다."));
                }

                return Column(
                  children: [
                    // 툴바
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("남은 업무: $incompleteCount개"),
                          TextButton.icon(
                            onPressed: incompleteCount == 0
                                ? null
                                : () => _copyIncompleteTasks(items),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text("복사"),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // 리스트
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final task = item.task;
                          final project = item.project;

                          return ListTile(
                            leading: Checkbox(
                              value: task.isCompleted,
                              onChanged: (value) => _toggleTask(task),
                            ),
                            title: Row(
                              children: [
                                // 프로젝트 뱃지 (있으면 표시)
                                if (project != null)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      project.name,
                                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isCompleted ? Colors.grey : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => _deleteTask(task.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
