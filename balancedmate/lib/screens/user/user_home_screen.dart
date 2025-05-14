// lib/screens/user/user_home_screen.dart
import 'package:balanced_meal/core/routes.dart';
import 'package:balanced_meal/models/recipe_model.dart';
import 'package:balanced_meal/services/recipe_service.dart';
import 'package:flutter/material.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Recipes')),
      body: StreamBuilder<List<Recipe>>(
        stream: RecipeService().getRecipes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = snapshot.data!;

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return ListTile(
                leading: recipe.imageUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(recipe.imageUrl!))
                    : const CircleAvatar(child: Icon(Icons.fastfood)),
                title: Text(recipe.title),
                subtitle: Text('${recipe.cookingTime} mins'),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.recipeDetail,
                  arguments: recipe.id,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
