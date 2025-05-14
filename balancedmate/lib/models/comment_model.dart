// lib/models/comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String recipeId;
  final String userId;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      recipeId: map['recipeId'],
      userId: map['userId'],
      text: map['text'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'userId': userId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
