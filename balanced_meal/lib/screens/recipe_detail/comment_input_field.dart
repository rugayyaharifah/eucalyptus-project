import 'package:balanced_meal/models/comment_model.dart';
import 'package:balanced_meal/services/comment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CommentInputField extends StatefulWidget {
  final String recipeId;
  final Color accentColor;

  const CommentInputField({
    super.key,
    required this.recipeId,
    required this.accentColor,
  });

  @override
  State<CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  final _commentController = TextEditingController();
  final _commentService = CommentService();
  final _auth = FirebaseAuth.instance;

  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty) return;

    final comment = Comment(
      id: const Uuid().v4(),
      recipeId: widget.recipeId,
      userId: _auth.currentUser!.uid,
      text: _commentController.text,
      timestamp: DateTime.now(),
    );

    await _commentService.addComment(comment);
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700]! : Colors.grey[200]!;
    final avatarColor = isDarkMode ? Colors.grey[700]! : Colors.grey[200]!;
    final avatarIconColor = isDarkMode ? Colors.grey[400]! : Colors.grey[500]!;
    final hintColor = isDarkMode ? Colors.grey[400] : Colors.grey[500];
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: avatarColor,
            child: Icon(Icons.person, size: 18, color: avatarIconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: TextStyle(color: hintColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: widget.accentColor),
            onPressed: _submitComment,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
