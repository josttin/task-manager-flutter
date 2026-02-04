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
    TaskPriority priority = TaskPriority.media,
  }) async {
    if (_userData != null) {
      await FirebaseFirestore.instance.collection('tasks').add({
        "title": title,
        "description": description,
        "userId": _userData!['uid'],
        "isDone": false,
        "dueDate": Timestamp.fromDate(dueDate),
        "assignedTo": assignedTo,
        "assignedToName": assignedToName,
        "status": 'pendiente',
        "priority": priority.name,
        "isPinned": false,
        "progressLogs": [],
      });
    }
  }

  Future<void> togglePin(String taskId, bool currentPinStatus) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'isPinned': !currentPinStatus,
    });
  }

  Future<void> addTaskProgress(String taskId, String message) async {
    final log = {'msg': message, 'date': Timestamp.now()};
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'progressLogs': FieldValue.arrayUnion([log]),
    });
  }

  // --- CORREGIDO: Solo guarda la URL, no finaliza la tarea ---
  Future<void> addEvidencia(String taskId, String imageUrl) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'evidenciaUrl': imageUrl,
      // Quitamos isDone y status de aquí para permitir subir fotos sin cerrar la tarea
    });
  }

  // --- Flujo de Cierre y Revisión ---

  // Este es el método que realmente marca la tarea como terminada
  Future<void> sendToReview(String taskId, String comment) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'isDone': true,
      'status': 'revision',
      'completionComment': comment,
      'completedAt': Timestamp.now(),
    });
  }

  Future<void> approveTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'status': 'completada',
      'isDone': true, // Se mantiene en true para el reporte individual
      'approvedAt': Timestamp.now(),
    });
  }

  Future<void> rejectTask(String taskId, String reason) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'isDone':
          false, // Vuelve a false para que no salga en reportes de "terminadas"
      'status': 'pendiente',
      'progressLogs': FieldValue.arrayUnion([
        {'msg': 'RECHAZADO POR JEFE: $reason', 'date': Timestamp.now()},
      ]),
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _dbService.deleteTask(taskId);
  }
}
