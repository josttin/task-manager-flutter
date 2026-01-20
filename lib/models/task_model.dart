import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description; // Nuevo
  final String userId;
  final bool isDone;
  final DateTime dueDate; // Ahora no es opcional
  final String assignedTo;
  final String assignedToName;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.isDone,
    required this.dueDate,
    required this.assignedTo,
    required this.assignedToName,
  });

  factory TaskModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return TaskModel(
      id: snap.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      userId: data['userId'] ?? '',
      isDone: data['isDone'] ?? false,
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      assignedTo: data['assignedTo'] ?? '',
      assignedToName: data['assignedToName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "title": title,
    "description": description,
    "userId": userId,
    "isDone": isDone,
    "dueDate": Timestamp.fromDate(dueDate),
    "assignedTo": assignedTo,
    "assignedToName": assignedToName,
  };
}
