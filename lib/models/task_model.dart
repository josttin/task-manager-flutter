import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String userId; // El ID del jefe que la creó
  final bool isDone;
  final DateTime dueDate;
  final String assignedTo; // UID del empleado
  final String assignedToName;
  // Campos nuevos para el flujo de revisión gratuito
  final String? completionComment;
  final DateTime? completedAt;
  final String status; // 'pendiente', 'revision', 'completada'

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.isDone,
    required this.dueDate,
    required this.assignedTo,
    required this.assignedToName,
    this.completionComment,
    this.completedAt,
    this.status = 'pendiente', // Valor por defecto
  });

  factory TaskModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return TaskModel(
      id: snap.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      userId: data['userId'] ?? '',
      isDone: data['isDone'] ?? false,
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      assignedTo: data['assignedTo'] ?? '',
      assignedToName: data['assignedToName'] ?? '',
      completionComment: data['completionComment'],
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'pendiente',
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
    "completionComment": completionComment,
    "completedAt": completedAt != null
        ? Timestamp.fromDate(completedAt!)
        : null,
    "status": status,
  };
}
