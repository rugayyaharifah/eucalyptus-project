// lib/screens/favorites_screen.dart
import 'package:balanced_meal/models/recipe_model.dart';
import 'package:balanced_meal/services/favorite_service.dart';
import 'package:balanced_meal/services/recipe_service.dart';
import 'package:balanced_meal/widgets/recipe_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
   
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Color _primaryColor = const Color(0xFFFFC107); // Amber 500
  final Color _secondaryColor = const Color(0xFFFFF3E0); // Amber 50
  final Color _accentColor = const Color(0xFFFFA000); // Amber 700

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in to view favorites',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search favorite recipes...',
                prefixIcon: Icon(Icons.search, color: _accentColor),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: _accentColor),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: FavoriteService().getUserFavorites(user.uid),
              builder: (context, favoriteSnapshot) {
                if (favoriteSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${favoriteSnapshot.error}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                if (!favoriteSnapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: _accentColor),
                  );
                }

                final favoriteRecipeIds = favoriteSnapshot.data!;

                if (favoriteRecipeIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No favorite recipes yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the heart icon on recipes to add them here',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return StreamBuilder<List<Recipe>>(
                  stream: RecipeService().getRecipes(),
                  builder: (context, recipeSnapshot) {
                    if (recipeSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${recipeSnapshot.error}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }

                    if (!recipeSnapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(color: _accentColor),
                      );
                    }

                    final favoriteRecipes = recipeSnapshot.data!
                        .where((recipe) =>
                            favoriteRecipeIds.contains(recipe.id) &&
                            recipe.title
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()))
                        .toList();

                    if (favoriteRecipes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No recipes match your search',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.6,
                      ),
                      itemCount: favoriteRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = favoriteRecipes[index];
                        return RecipeCard(
                          recipe: recipe,
                          primaryColor: _primaryColor,
                          secondaryColor: _secondaryColor,
                          accentColor: _accentColor,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
