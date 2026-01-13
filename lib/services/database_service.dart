import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtener tareas en tiempo real
  Stream<List<TaskModel>> getTasks() {
    return _db
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromSnapshot(doc)).toList(),
        );
  }

  // Agregar nueva tarea
  Future<void> addTask(String title) async {
    await _db.collection('tasks').add({
      'title': title,
      'isDone': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Actualizar estado de la tarea
  Future<void> toggleTask(TaskModel task) async {
    await _db.collection('tasks').doc(task.id).update({'isDone': !task.isDone});
  }

  // Eliminar tarea
  Future<void> deleteTask(String id) async {
    await _db.collection('tasks').doc(id).delete();
  }
}
