import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        data['uid'] = uid;
        return data;
      }
    } catch (e) {
      print("Error al obtener usuario: $e");
    }
    return null;
  }

  Stream<List<TaskModel>> getTasks(String uid, String role) {
    // Quita el .orderBy por ahora para probar
    if (role == 'jefe') {
      return _db
          .collection('tasks')
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((doc) => TaskModel.fromSnapshot(doc)).toList(),
          );
    } else {
      return _db
          .collection('tasks')
          .where('assignedTo', isEqualTo: uid)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((doc) => TaskModel.fromSnapshot(doc)).toList(),
          );
    }
  }

  Stream<List<Map<String, dynamic>>> getEmployees() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'empleado')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = doc.data();
            // Si 'name' es nulo o vacío, usa 'email'
            String displayName =
                (data['name'] != null && data['name'].toString().isNotEmpty)
                ? data['name']
                : (data['email'] ?? 'Usuario sin correo');

            return {'uid': doc.id, 'name': displayName};
          }).toList();
        });
  }

  Future<void> addTask({
    required String title,
    required String description,
    required String creatorUid,
    required DateTime dueDate,
    required String assignedTo,
    required String assignedToName,
  }) async {
    await _db.collection('tasks').add({
      'title': title,
      'description': description,
      'userId': creatorUid,
      'isDone': false,
      'createdAt': FieldValue.serverTimestamp(),
      'dueDate': Timestamp.fromDate(dueDate),
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
    });
  }

  Future<void> updateTaskStatus(String taskId, bool status) async {
    await _db.collection('tasks').doc(taskId).update({'isDone': status});
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }
}
