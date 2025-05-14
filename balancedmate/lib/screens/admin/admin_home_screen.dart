// lib/screens/admin/admin_home_screen.dart
import 'package:balanced_meal/screens/recipe_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:balanced_meal/core/routes.dart';
import 'package:balanced_meal/models/recipe_model.dart';
import 'package:balanced_meal/services/recipe_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _adminScreens = [
    const _RecipeManagementScreen(), // Moved recipe list to separate widget
    const _UserManagementScreen(), // Placeholder for user management
    const _AdminSettingsScreen(), // Placeholder for settings
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          if (_currentIndex == 0) // Only show add button on recipe screen
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.addRecipe),
            ),
        ],
      ),
      body: _adminScreens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Moved recipe list to a separate private widget
class _RecipeManagementScreen extends StatelessWidget {
  const _RecipeManagementScreen();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Recipe>>(
      stream: RecipeService().getRecipes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final recipe = snapshot.data![index];
            return Dismissible(
              key: Key(recipe.id),
              background: Container(color: Colors.red),
              confirmDismiss: (_) async {
                return await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Recipe'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) => RecipeService().deleteRecipe(recipe.id),
              child: InkWell(
                // <-- Wrap ListTile with InkWell
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RecipeDetailScreen(recipeId: recipe.id),
                  ),
                ),
                child: ListTile(
                  title: Text(recipe.title),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.addRecipe,
                      arguments: recipe,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Placeholder for user management
class _UserManagementScreen extends StatelessWidget {
  const _UserManagementScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('User Management Screen'));
  }
}

// Placeholder for admin settings
class _AdminSettingsScreen extends StatelessWidget {
  const _AdminSettingsScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Admin Settings Screen'));
  }
}
