import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context, listen: false);

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: task.isDone,
          onChanged: (_) => provider.toggleTask(task),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => provider.deleteTask(task.id),
        ),
      ),
    );
  }
}
