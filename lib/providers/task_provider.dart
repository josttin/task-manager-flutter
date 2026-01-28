import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  Map<String, dynamic>? _userData;

  Map<String, dynamic>? get userData => _userData;

  Stream<List<TaskModel>> get tasksStream {
    if (_userData == null) return const Stream.empty();
    return _dbService.getTasks(_userData!['uid'], _userData!['role']);
  }

  void loadUser(String uid) async {
    final data = await _dbService.getUserData(uid);
    if (data != null) {
      _userData = data;
      notifyListeners();
    }
  }

  Future<void> addTask({
    required String title,
    required String description,
    required DateTime dueDate,
    required String assignedTo,
    required String assignedToName,
  }) async {
    if (_userData != null) {
      await _dbService.addTask(
        title: title,
        description: description,
        creatorUid: _userData!['uid'],
        dueDate: dueDate,
        assignedTo: assignedTo,
        assignedToName: assignedToName,
      );
    }
  }

  // --- NUEVO: Flujo de Cierre y Revisión ---

  /// Llamado por el EMPLEADO para enviar la tarea a revisión
  Future<void> sendToReview(String taskId, String comment) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'isDone': true,
      'status': 'revision',
      'completionComment': comment,
      'completedAt': Timestamp.now(),
    });
  }

  /// Llamado por el JEFE para dar el visto bueno final
  Future<void> approveTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'status': 'completada',
    });
  }

  /// Llamado por el JEFE para devolver la tarea con una razón
  Future<void> rejectTask(String taskId, String reason) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'isDone': false,
      'status': 'pendiente',
      'completionComment': 'RECHAZADO: $reason', // Guardamos el motivo aquí
    });
  }

  // Mantenemos los métodos básicos
  Future<void> toggleTask(TaskModel task) async {
    await _dbService.updateTaskStatus(task.id, !task.isDone);
  }

  Future<void> deleteTask(String taskId) async {
    await _dbService.deleteTask(taskId);
  }
}
