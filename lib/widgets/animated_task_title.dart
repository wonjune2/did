import 'package:did/database/app_database.dart';
import 'package:flutter/material.dart';

class AnimatedTaskTile extends StatefulWidget {
  final TaskWithProject item;
  final Function(Task) onToggle;
  final Function(int) onDelete;

  const AnimatedTaskTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<AnimatedTaskTile> createState() => _AnimatedTaskTileState();
}

class _AnimatedTaskTileState extends State<AnimatedTaskTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _sizeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  // 체크박스 눌렀을 때 실행되는 함수
  void _handleCompletion(bool? value) {
    if (value == true) {
      // 1. 완료 체크가 들어오면 애니메이션 실행 (정방향: 0 -> 1)
      _controller.forward().then((_) {
        widget.onToggle(widget.item.task);
      });
    } else {
      widget.onToggle(widget.item.task);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.item.task;
    final project = widget.item.project;

    return SizeTransition(
      sizeFactor: Tween<double>(begin: 1.0, end: 0.0).animate(_sizeAnimation),
      axisAlignment: 0.0,
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeAnimation),
        child: ListTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: _handleCompletion,
            shape: const CircleBorder(),
          ),
          title: Row(
            children: [
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
            onPressed: () => widget.onDelete(task.id),
          ),
        ),
      ),
    );
  }
}
