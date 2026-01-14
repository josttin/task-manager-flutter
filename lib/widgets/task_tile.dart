import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'glass_card.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml

class TaskTile extends StatelessWidget {
  final TaskModel task;
  const TaskTile({super.key, required this.task});

  Color _getDateColor(DateTime date) {
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return Colors.redAccent; // Vencida
    }
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GlassCard(
        opacity: task.isDone ? 0.05 : 0.15,
        child: ListTile(
          leading: Checkbox(
            value: task.isDone,
            shape: const CircleBorder(),
            activeColor: Colors.greenAccent,
            onChanged: (_) => provider.toggleTask(task),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: task.isDone ? TextDecoration.lineThrough : null,
              color: task.isDone ? Colors.white38 : Colors.white,
            ),
          ),
          subtitle: task.dueDate != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: _getDateColor(task.dueDate!),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "Vence: ${DateFormat('dd/MM').format(task.dueDate!)}",
                        style: TextStyle(
                          color: _getDateColor(task.dueDate!),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
          trailing: IconButton(
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Colors.white70,
            ),
            onPressed: () => provider.deleteTask(task.id),
          ),
        ),
      ),
    );
  }
}
