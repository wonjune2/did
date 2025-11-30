import 'package:did/utils/report_format.dart';
import 'package:did/widgets/animated_task_title.dart';
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

    void submit() {
      if (projectController.text.isNotEmpty) {
        db.insertProject(projectController.text);
        Navigator.pop(context);
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("새 프로젝트/고객사 추가"),
        content: TextField(
          controller: projectController,
          decoration: const InputDecoration(hintText: "예: 삼성전자, SK, 엔비디아"),
          autofocus: true,
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          FilledButton(onPressed: submit, child: const Text("추가")),
        ],
      ),
    );
  }

  // [수정] 토글 시 DB 업데이트
  void _toggleTask(Task task) {
    db.toggleTask(task);
    // 팁: 여기서 SnackBar를 띄워주면 좋습니다.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("업무 완료! 고생하셨습니다 🎉"),
        action: SnackBarAction(
          label: "취소",
          onPressed: () => db.toggleTask(task), // 실수로 눌렀을 때 되돌리기
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteTask(int id) => db.deleteTask(id);

  // 복사 로직 (프로젝트 이름도 같이 복사되게 수정!)
  void _copyIncompleteTasks(List<TaskWithProject> items) {
    final incomplete = items.where((i) => !i.task.isCompleted).toList();
    if (incomplete.isEmpty) return;

    final Map<String, List<String>> groupedTasks = {};

    for (var item in incomplete) {
      final projectName = item.project?.name;
      if (projectName == null) {
        continue;
      }
      if (!groupedTasks.containsKey(projectName)) {
        groupedTasks[projectName] = [];
      }
      groupedTasks[projectName]!.add(item.task.title);
    }

    final buffer = StringBuffer();
    // 반복문을 돌리기 위한 인덱스 변수
    int projectIndex = 0;

    for (var entry in groupedTasks.entries) {
      // 1. 프로젝트 이름 출력 (ex: 한미글로벌 )
      buffer.write("${entry.key} ");

      // 2. 해당 프로젝트의 업무들을 쉼표로 연결해서 한 방에 출력
      // join 함수가 알아서 사이사이에만 쉼표를 넣어줍니다.
      buffer.write(entry.value.join(", "));

      // 3. [핵심] 마지막 프로젝트가 아니라면, 다음 프로젝트와의 사이에 쉼표 추가
      if (projectIndex < groupedTasks.length - 1) {
        buffer.write(", ");
      }

      // 인덱스 증가
      projectIndex++;
    }

    final result = ReportFormat().dailyReportFormat(buffer.toString());

    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('복사 완료!')));
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
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text("프로젝트 없음 (일반)"),
                              ),
                              ...projects.map(
                                (p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
                                ),
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
              stream: db.watchIncompleteTasksWithProject(), // 수정된 쿼리 호출
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!;
                final incompleteCount = items
                    .where((i) => !i.task.isCompleted)
                    .length;

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

                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];

                          // [핵심] AnimatedTaskTile 사용
                          return AnimatedTaskTile(
                            key: ValueKey(item.task.id), // 키 필수!
                            item: item,
                            onToggle: (task) => _toggleTask(task),
                            onDelete: (id) => _deleteTask(id),
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
