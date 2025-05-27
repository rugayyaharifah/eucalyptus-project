import 'package:balanced_meal/models/recipe_model.dart';
import 'package:balanced_meal/providers/user_role_provider.dart';
import 'package:balanced_meal/screens/recipe_detail/recipe_detail_content.dart';
import 'package:balanced_meal/services/favorite_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecipeDetailScreen extends ConsumerWidget {
  final String recipeId;
  final Color _primaryColor = const Color(0xFFFFC107);
  final Color _secondaryColor = const Color(0xFFFFF3E0);
  final Color _accentColor = const Color(0xFFFFA000);

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _accentColor),
        actions: [
          if (user != null)
            StreamBuilder<bool>(
              stream: FavoriteService().isFavoriteStream(user.uid, recipeId),
              builder: (context, snapshot) {
                final isFavorite = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : _accentColor,
                  ),
                  onPressed: () async {
                    if (isFavorite) {
                      await FavoriteService()
                          .removeFavorite(user.uid, recipeId);
                    } else {
                      await FavoriteService().addFavorite(user.uid, recipeId);
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: FutureBuilder<Recipe>(
        future: _getRecipe(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: _accentColor));
          }
          if (!snapshot.hasData) {
            return Center(
              child: Text(
                'Recipe not found',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          final recipe = snapshot.data!;
          return RecipeDetailContent(
            recipe: recipe,
            isAdmin: isAdmin,
            user: user,
            primaryColor: _primaryColor,
            secondaryColor: _secondaryColor,
            accentColor: _accentColor,
          );
        },
      ),
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
