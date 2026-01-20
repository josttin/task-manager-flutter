import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  Map<String, dynamic>? _userData; // Cambiado a Map explícitamente

  Map<String, dynamic>? get userData => _userData;

  Stream<List<TaskModel>> get tasksStream {
    if (_userData == null) return const Stream.empty();
    // CORRECCIÓN: Usar ['uid'] y ['role']
    return _dbService.getTasks(_userData!['uid'], _userData!['role']);
  }

  void loadUser(String uid) async {
    final data = await _dbService.getUserData(uid);
    if (data != null) {
      _userData = data;
      notifyListeners();
    }
  }

  Future<void> addTask(
    String title, {
    required String description,
    required DateTime dueDate,
    required String assignedTo,
    required String assignedToName,
  }) async {
    if (_userData != null) {
      await _dbService.addTask(
        title: title,
        description: description,
        creatorUid: _userData!['uid'], // CORRECCIÓN: ['uid']
        dueDate: dueDate,
        assignedTo: assignedTo,
        assignedToName: assignedToName,
      );
    }
  }

  Future<void> toggleTask(TaskModel task) async {
    await _dbService.updateTaskStatus(task.id, !task.isDone);
  }

  Future<void> deleteTask(String taskId) async {
    await _dbService.deleteTask(taskId);
  }
}
