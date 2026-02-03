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

  Stream<List<TaskModel>> getTasks(String uid, String role) {
    Query query = _db.collection('tasks');

    if (role != 'jefe') {
      query = query.where('assignedTo', isEqualTo: uid);
    }

    return query.snapshots().map((snap) {
      List<TaskModel> tasks = snap.docs
          .map((doc) => TaskModel.fromSnapshot(doc))
          .toList();

      // --- ORDENAMIENTO LÓGICO ---
      tasks.sort((a, b) {
        // 1. Priorizar Anclados (Pinned)
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;

        // 2. Por Estado (Pendientes y Revisión primero que Completadas)
        if (a.status != 'completada' && b.status == 'completada') return -1;
        if (a.status == 'completada' && b.status != 'completada') return 1;

        // 3. Por Prioridad (Alta > Media > Baja)
        int priorityA = a.priority == TaskPriority.alta
            ? 0
            : (a.priority == TaskPriority.media ? 1 : 2);
        int priorityB = b.priority == TaskPriority.alta
            ? 0
            : (b.priority == TaskPriority.media ? 1 : 2);
        if (priorityA != priorityB) return priorityA.compareTo(priorityB);

        // 4. Por Fecha de vencimiento
        return a.dueDate.compareTo(b.dueDate);
      });

      return tasks;
    });
  }

  // Actualizamos el addTask para que incluya los nuevos campos por defecto
  Future<void> addTask({
    required String title,
    required String description,
    required String creatorUid,
    required DateTime dueDate,
    required String assignedTo,
    required String assignedToName,
    String priority = 'media', // Nuevo
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
      'status': 'pendiente',
      'priority': priority,
      'isPinned': false,
      'progressLogs': [],
    });
  }

  Future<void> updateTaskStatus(String taskId, bool status) async {
    await _db.collection('tasks').doc(taskId).update({'isDone': status});
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }
}
