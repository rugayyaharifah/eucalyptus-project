// lib/screens/recipe_detail_screen.dart
import 'package:balanced_meal/models/comment_model.dart';
import 'package:balanced_meal/models/recipe_model.dart';
import 'package:balanced_meal/providers/user_role_provider.dart';
import 'package:balanced_meal/services/comment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class RecipeDetailScreen extends ConsumerWidget  {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = ref.watch(isAdminProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recipe Details')),
      body: FutureBuilder<Recipe>(
        future: _getRecipe(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Recipe not found'));
          }

          final recipe = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder (ImgBB URL will replace later)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: recipe.imageUrl != null
                        ? Image.network(recipe.imageUrl!)
                        : const Icon(Icons.fastfood, size: 50),
                  ),
                ),
                const SizedBox(height: 16),
                Text(recipe.title,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16),
                    const SizedBox(width: 4),
                    Text('${recipe.cookingTime} mins'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Ingredients',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...recipe.ingredients
                    .map((ingredient) => Text('- $ingredient'))
                    .toList(),
                const SizedBox(height: 16),
                const Text('Steps',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...recipe.steps
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('${entry.key + 1}. ${entry.value}'),
                      ),
                    )
                    .toList(),
                    const Divider(),
                _buildCommentSection(context, recipe.id, ref),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentSection(BuildContext context, String recipeId, WidgetRef ref,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = ref.watch(isAdminProvider); // this is the problem

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Comments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (user != null) CommentInputField(recipeId: recipeId),
        if (user == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child:
                Text('Log in to comment', style: TextStyle(color: Colors.grey)),
          ),
        const SizedBox(height: 16),
        StreamBuilder<List<Comment>>(
          stream: CommentService().getComments(recipeId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final comments = snapshot.data ?? [];

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: FutureBuilder(
                    future: _getUsername(comment.userId),
                    builder: (context, snapshot) {
                      return Text(snapshot.data ?? 'Anonymous');
                    },
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment.text),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().add_jm().format(comment.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                 trailing: (isAdmin || user?.uid == comment.userId)
                      ? IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _deleteComment(context, comment.id),
                        )
                      : null,
                );
              },
            );
          },
        ),
      ],
    );
  }
  
  Future<Recipe> _getRecipe(BuildContext context) async {
    final doc = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .get();
    return Recipe.fromMap(doc.data()!);
  }
}

class CommentInputField extends StatefulWidget {
  final String recipeId;

  const CommentInputField({super.key, required this.recipeId});

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
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
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

// 2. Complete Comment Section Builder


// Helper methods
Future<String?> _getUsername(String userId) async {
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return doc.get('name');
}

void _deleteComment(BuildContext context, String commentId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Comment'),
      content: const Text('Are you sure?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            CommentService().deleteComment(commentId);
            Navigator.pop(context);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}

// 3. Delete Confirmation Dialog
void _showDeleteDialog(BuildContext context, String commentId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Comment'),
      content: const Text('Are you sure you want to delete this comment?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
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
