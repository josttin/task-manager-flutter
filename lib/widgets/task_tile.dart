import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../services/report_service.dart'; // Importante
import 'package:intl/intl.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  const TaskTile({super.key, required this.task});

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.alta:
        return Colors.redAccent;
      case TaskPriority.media:
        return Colors.orangeAccent;
      case TaskPriority.baja:
        return Colors.blueAccent;
    }
  }

  Color _getDateColor(DateTime date) {
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return Colors.redAccent;
    }
    return Colors.greenAccent;
  }

  void _showProgressDialog(BuildContext context, TaskProvider provider) {
    final TextEditingController progressController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D47A1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Registrar Avance",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: progressController,
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Escribe qué has hecho hasta ahora...",
            hintStyle: TextStyle(color: Colors.white30),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () {
              if (progressController.text.isNotEmpty) {
                provider.addTaskProgress(task.id, progressController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("GUARDAR AVANCE"),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, TaskProvider provider) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF310D0D),
        title: const Text(
          "Rechazar Tarea",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => provider
                .rejectTask(task.id, reasonController.text)
                .then((_) => Navigator.pop(context)),
            child: const Text("RECHAZAR"),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, TaskProvider provider) {
    final TextEditingController commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text(
          "Finalizar Tarea",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: commentController,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => provider
                .sendToReview(task.id, commentController.text)
                .then((_) => Navigator.pop(context)),
            child: const Text("ENVIAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final bool isBoss = provider.userData?['role'] == 'jefe';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: task.isPinned
                ? Colors.blueAccent.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: task.isPinned ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(15, 5, 5, 5),
              leading: isBoss
                  ? Icon(
                      task.status == 'completada'
                          ? Icons.check_circle
                          : Icons.pending_actions,
                      color: task.status == 'completada'
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    )
                  : Checkbox(
                      value: task.isDone,
                      shape: const CircleBorder(),
                      activeColor: Colors.greenAccent,
                      onChanged: (val) {
                        if (val == true && task.status == 'pendiente')
                          _showCompletionDialog(context, provider);
                      },
                    ),
              title: Row(
                children: [
                  if (task.isPinned)
                    const Icon(
                      Icons.push_pin,
                      size: 16,
                      color: Colors.blueAccent,
                    ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: task.status == 'completada'
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.status == 'completada'
                            ? Colors.white38
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildPriorityBadge(task.priority),
                      const SizedBox(width: 8),
                      Text(
                        "Vence: ${DateFormat('dd/MM').format(task.dueDate)}",
                        style: TextStyle(
                          color: _getDateColor(task.dueDate),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (task.progressLogs.isNotEmpty &&
                      task.status == 'pendiente')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Último avance: ${task.progressLogs.last['msg']}",
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBoss) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () =>
                          ReportService.generateIndividualReport(task),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.push_pin,
                        color: task.isPinned
                            ? Colors.blueAccent
                            : Colors.white24,
                        size: 20,
                      ),
                      onPressed: () =>
                          provider.togglePin(task.id, task.isPinned),
                    ),
                  ] else
                    IconButton(
                      icon: const Icon(
                        Icons.add_comment_outlined,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                      onPressed: () => _showProgressDialog(context, provider),
                    ),
                ],
              ),
            ),
            if (isBoss && task.status == 'revision')
              _buildBossActions(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority).withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getPriorityColor(priority).withOpacity(0.5)),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(
          color: _getPriorityColor(priority),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBossActions(BuildContext context, TaskProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showRejectDialog(context, provider),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
              ),
              child: const Text(
                "RECHAZAR",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => provider.approveTask(task.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
              ),
              child: const Text(
                "APROBAR",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
