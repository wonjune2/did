import 'package:did/database/app_database.dart';
import 'package:did/main.dart';
import 'package:flutter/material.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  // 텍스트 입력기 제어용 컨트롤러
  final TextEditingController _textController = TextEditingController();

  // 업무 추가 함수
  void _addTask(String title) {
    if (title.isEmpty) return;
    db.insertTask(title);
    _textController.clear();
  }

  // 토글 기능 (Task 객체를 통째로 넘김)
  void _toggleTask(Task task) {
    db.toggleTask(task);
  }

  void _deleteTask(int index) {
    db.deleteTask(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 상단 입력창 영역
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: '할 일을 입력하고 Enter를 누르세요.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.add_task),
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
          ),

          // 리스트 보여주기 (StreamBuilder 사용)
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: db.watchAllTasks(),
              builder: (context, snapshot) {
                // 데이터 로딩 중일 때
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data!;

                if (tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      '등록된 업무가 없습니다. \n업무를 추가해보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (value) => _toggleTask(task),
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? Colors.grey : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _deleteTask(task.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
