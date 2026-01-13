import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final isJefe = provider.userData?.role == 'jefe';

    return Card(
      color: task.isDone ? Colors.grey[200] : Colors.white,
      child: ListTile(
        leading: Checkbox(
          value: task.isDone,
          onChanged: (_) => provider.toggleTask(task),
        ),
        title: Text(task.title),
        subtitle: isJefe
            ? Text("Asignado a: ${task.id}")
            : null, // Aquí puedes mejorar el modelo para traer el email si gustas
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => provider.deleteTask(task.id),
        ),
      ),
    );
  }
}
