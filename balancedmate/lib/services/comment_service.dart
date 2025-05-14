// lib/services/comment_service.dart
import 'package:balanced_meal/models/comment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Comment>> getComments(String recipeId) {
    return _firestore
        .collection('comments')
        .where('recipeId', isEqualTo: recipeId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Comment.fromMap(doc.data())).toList());
  }

  Future<void> addComment(Comment comment) async {
    await _firestore
        .collection('comments')
        .doc(comment.id)
        .set(comment.toMap());
  }

  Future<void> deleteComment(String commentId) async {
    await _firestore.collection('comments').doc(commentId).delete();
  }
}
