import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream dinámico: Si es jefe ve todo, si es empleado solo sus tareas
  Stream<List<TaskModel>> getTasks(String uid, String role) {
    Query query = _db.collection('tasks');

    if (role == 'empleado') {
      query = query.where('userId', isEqualTo: uid);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromSnapshot(doc)).toList(),
        );
  }

  Future<void> addTask(String title, String uid, {DateTime? dueDate}) async {
    await _db.collection('tasks').add({
      'title': title,
      'userId': uid,
      'isDone': false,
      'createdAt': FieldValue.serverTimestamp(),
      'dueDate': dueDate != null
          ? Timestamp.fromDate(dueDate)
          : null, // Agregar esto
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
