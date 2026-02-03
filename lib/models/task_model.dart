import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { baja, media, alta }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String userId;
  final bool isDone;
  final DateTime dueDate;
  final String assignedTo;
  final String assignedToName;
  final String? completionComment;
  final DateTime? completedAt;
  final String status;

  // NUEVOS CAMPOS
  final TaskPriority priority;
  final bool isPinned;
  final List<Map<String, dynamic>> progressLogs;

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
    this.status = 'pendiente',
    this.priority = TaskPriority.media,
    this.isPinned = false,
    this.progressLogs = const [],
  });

  factory TaskModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;

    // Mapeo de prioridad desde String a Enum
    TaskPriority priorityEnum = TaskPriority.media;
    if (data['priority'] == 'alta') priorityEnum = TaskPriority.alta;
    if (data['priority'] == 'baja') priorityEnum = TaskPriority.baja;

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
      priority: priorityEnum,
      isPinned: data['isPinned'] ?? false,
      progressLogs: List<Map<String, dynamic>>.from(data['progressLogs'] ?? []),
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
    "priority": priority.name, // Guarda 'baja', 'media' o 'alta'
    "isPinned": isPinned,
    "progressLogs": progressLogs,
  };
}
