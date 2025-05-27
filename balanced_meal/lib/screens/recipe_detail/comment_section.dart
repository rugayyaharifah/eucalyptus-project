import 'package:balanced_meal/models/comment_model.dart';
import 'package:balanced_meal/screens/recipe_detail/comment_input_field.dart';
import 'package:balanced_meal/services/comment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentSection extends StatelessWidget {
  final String recipeId;
  final bool isAdmin;
  final User? user;
  final Color accentColor;
  final Color secondaryColor;

  const CommentSection({
    required this.recipeId,
    required this.isAdmin,
    required this.user,
    required this.accentColor,
    required this.secondaryColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(isAdmin.toString());
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final baseTextColor = isDarkMode ? Colors.white : Colors.black;
    final cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    final hintTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 16),
        if (user != null)
          CommentInputField(
            recipeId: recipeId,
            accentColor: accentColor,
          ),
        if (user == null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              'Log in to leave a comment',
              style: TextStyle(color: hintTextColor),
            ),
          ),
        const SizedBox(height: 24),
        StreamBuilder<List<Comment>>(
          stream: CommentService().getComments(recipeId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Error loading comments',
                style: TextStyle(color: hintTextColor),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: accentColor),
              );
            }

            final comments = snapshot.data ?? [];

            if (comments.isEmpty) {
              return Center(
                child: Text(
                  'No comments yet',
                  style: TextStyle(color: hintTextColor),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                
                final comment = comments[index];
                final canDelete = isAdmin ||
                    (user?.uid != null &&
                        user!.uid.toString() == comment.userId.toString());

                debugPrint('User UID: ${user?.uid}');
                debugPrint('Comment UID: ${comment.userId}');
                debugPrint('Is Admin: $isAdmin');
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                    boxShadow: isDarkMode
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: secondaryColor,
                      child: Icon(Icons.person, color: accentColor),
                    ),
                    title: FutureBuilder<String?>(
                      future: _getUsername(comment.userId),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Anonymous',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: baseTextColor,
                          ),
                        );
                      },
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          comment.text,
                          style: TextStyle(color: baseTextColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat.yMMMd().add_jm().format(comment.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: hintTextColor,
                          ),
                        ),
                      ],
                    ),
                    
                    trailing: canDelete
                        ? IconButton(
                            icon: Icon(Icons.delete,
                                size: 20, color: Colors.red[400]),
                            onPressed: () =>
                                _showDeleteDialog(context, comment.id),
                          )
                        : null,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<String?> _getUsername(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data()?['name'] ?? 'Anonymous'; // Fallback if name is null
      }
      return 'Anonymous';
    } catch (e) {
      debugPrint('Error fetching username: $e');
      return 'Anonymous';
    }
  }

  void _showDeleteDialog(BuildContext context, String commentId) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode
            ? Colors.grey[900]
            : Theme.of(context).dialogBackgroundColor,
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: accentColor)),
          ),
          TextButton(
            onPressed: () {
              CommentService().deleteComment(commentId);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  

}

