import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  String id;
  String title;
  bool isDone;
  DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.createdAt,
  });

  // Convertir de Firestore a Objeto
  factory TaskModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return TaskModel(
      id: snap.id,
      title: data['title'] ?? '',
      isDone: data['isDone'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convertir de Objeto a JSON para Firestore
  Map<String, dynamic> toJson() => {
    "title": title,
    "isDone": isDone,
    "createdAt": createdAt,
  };
}
