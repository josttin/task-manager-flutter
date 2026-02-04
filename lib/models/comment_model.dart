import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String senderName;
  final String senderId;
  final String message;
  final DateTime timestamp;

  CommentModel({
    required this.id,
    required this.senderName,
    required this.senderId,
    required this.message,
    required this.timestamp,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      senderName: data['senderName'] ?? '',
      senderId: data['senderId'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderName': senderName,
      'senderId': senderId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
