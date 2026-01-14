import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  String id;
  String title;
  bool isDone;
  DateTime createdAt;
  String userId;
  String priority; // 'Baja', 'Media', 'Alta'
  DateTime? dueDate;

  TaskModel({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.createdAt,
    required this.userId,
    this.priority = 'Media',
    this.dueDate,
  });

  factory TaskModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return TaskModel(
      id: snap.id,
      title: data['title'] ?? '',
      isDone: data['isDone'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      priority: data['priority'] ?? 'Media',
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "title": title,
    "isDone": isDone,
    "createdAt": createdAt,
    "userId": userId,
    "priority": priority,
    "dueDate": dueDate,
  };
}
