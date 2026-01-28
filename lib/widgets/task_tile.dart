import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'package:intl/intl.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  const TaskTile({super.key, required this.task});

  Color _getDateColor(DateTime date) {
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return Colors.redAccent;
    }
    return Colors.greenAccent;
  }

  // --- DIÁLOGO DE RECHAZO PARA EL JEFE ---
  void _showRejectDialog(BuildContext context, TaskProvider provider) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF310D0D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Rechazar Tarea",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Explica el motivo del rechazo:",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                hintText: "Ej: No se limpió el área correctamente...",
                hintStyle: const TextStyle(color: Colors.white30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCELAR",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              if (reasonController.text.isNotEmpty) {
                provider.rejectTask(task.id, reasonController.text);
                Navigator.pop(context);
              }
            },
            child: const Text(
              "CONFIRMAR RECHAZO",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- DIÁLOGO DE CIERRE PARA EL EMPLEADO ---
  void _showCompletionDialog(BuildContext context, TaskProvider provider) {
    final TextEditingController commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A237E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Finalizar Tarea",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Describe brevemente qué hiciste:",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: commentController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                hintText: "Ej: Se realizó el mantenimiento...",
                hintStyle: const TextStyle(color: Colors.white30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCELAR",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
            ),
            onPressed: () {
              if (commentController.text.isNotEmpty) {
                provider.sendToReview(task.id, commentController.text);
                Navigator.pop(context);
              }
            },
            child: const Text(
              "ENVIAR REPORTE",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final bool isBoss = provider.userData?['role'] == 'jefe';
    final bool isRejected =
        task.completionComment?.contains("RECHAZADO") ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: task.status == 'revision'
                ? Colors.orangeAccent.withOpacity(0.5)
                : isRejected
                ? Colors.redAccent.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
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
                        if (val == true && task.status == 'pendiente') {
                          _showCompletionDialog(context, provider);
                        }
                      },
                    ),
              title: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  decoration: task.status == 'completada'
                      ? TextDecoration.lineThrough
                      : null,
                  color: task.status == 'completada'
                      ? Colors.white38
                      : Colors.white,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (task.completionComment != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      task.completionComment!,
                      style: TextStyle(
                        color: isRejected
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: isRejected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: _getDateColor(task.dueDate),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy').format(task.dueDate),
                            style: TextStyle(
                              color: _getDateColor(task.dueDate),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      _buildBadge(
                        task.assignedToName.split('@')[0].toUpperCase(),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: isBoss
                  ? IconButton(
                      icon: const Icon(
                        Icons.delete_sweep_outlined,
                        color: Colors.white30,
                      ),
                      onPressed: () => provider.deleteTask(task.id),
                    )
                  : null,
            ),
            if (isBoss && task.status == 'revision')
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 15, right: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        onPressed: () => _showRejectDialog(
                          context,
                          provider,
                        ), // Diálogo con motivo
                        icon: const Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        label: const Text(
                          "RECHAZAR",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                        ),
                        onPressed: () => provider.approveTask(task.id),
                        icon: const Icon(
                          Icons.check,
                          color: Colors.black,
                          size: 18,
                        ),
                        label: const Text(
                          "APROBAR",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
