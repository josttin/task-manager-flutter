import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  Stream<List<TaskModel>> get tasksStream => _dbService.getTasks();

  Future<void> addTask(String title) async {
    if (title.isNotEmpty) {
      await _dbService.addTask(title);
    }
  }

  Future<void> toggleTask(TaskModel task) async {
    await _dbService.toggleTask(task);
  }

  Future<void> deleteTask(String id) async {
    await _dbService.deleteTask(id);
  }
}
