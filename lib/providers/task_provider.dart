import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  UserModel? _userData;

  UserModel? get userData => _userData;

  // Cargar datos del usuario al iniciar
  Future<void> loadUser(String uid) async {
    _userData = await _authService.getUserData(uid);
    notifyListeners();
  }

  Stream<List<TaskModel>> get tasksStream {
    if (_userData == null) return const Stream.empty();
    return _dbService.getTasks(_userData!.uid, _userData!.role);
  }

  Future<void> addTask(String title) async {
    if (_userData != null) {
      await _dbService.addTask(title, _userData!.uid);
    }
  }

  Future<void> toggleTask(TaskModel task) async {
    await _dbService.toggleTask(task);
  }

  Future<void> deleteTask(String id) async {
    await _dbService.deleteTask(id);
  }
}
