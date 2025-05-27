import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:balanced_meal/core/routes.dart';
import 'package:balanced_meal/models/recipe_model.dart';
import 'package:balanced_meal/services/recipe_service.dart';
import 'package:balanced_meal/screens/recipe_detail/recipe_detail_screen.dart';
import 'package:balanced_meal/screens/favorites_screen.dart';
import 'package:balanced_meal/screens/meal_planner_screen.dart';
import 'package:balanced_meal/screens/profile_screen.dart';
import 'package:balanced_meal/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final Color _primaryColor = const Color(0xFFFFC107); // Amber 500
  final Color _secondaryColor = const Color(0xFFFFF3E0); // Amber 50
  final Color _accentColor = const Color(0xFFFFA000); // Amber 700
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final role = await AuthService().getUserRole(user.uid);
      setState(() {
        _userRole = role;
      });
    }
  }

  List<Widget> get _screens {
    if (_userRole == 'admin') {
      return [
        const _RecipeManagementScreen(isAdmin: true),
        const FavoritesScreen(),
        const MealPlannerScreen(),
        const ProfileScreen(),
      ];
    } else {
      return [
        const _RecipeManagementScreen(isAdmin: false),
        const FavoritesScreen(),
        const MealPlannerScreen(),
        const ProfileScreen(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        iconTheme: theme.appBarTheme.iconTheme?.copyWith(color: _accentColor),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: _accentColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        elevation: theme.bottomNavigationBarTheme.elevation,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == 0
                    ? isDarkMode
                        ? Colors.grey[800]
                        : _secondaryColor
                    : Colors.transparent,
              ),
              child: const Icon(Icons.restaurant_menu),
            ),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == 1
                    ? isDarkMode
                        ? Colors.grey[800]
                        : _secondaryColor
                    : Colors.transparent,
              ),
              child: const Icon(Icons.favorite),
            ),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == 2
                    ? isDarkMode
                        ? Colors.grey[800]
                        : _secondaryColor
                    : Colors.transparent,
              ),
              child: const Icon(Icons.calendar_month),
            ),
            label: 'Meal Plan',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == 3
                    ? isDarkMode
                        ? Colors.grey[800]
                        : _secondaryColor
                    : Colors.transparent,
              ),
              child: const Icon(Icons.person),
            ),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 && _userRole == 'admin'
          ? FloatingActionButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.addRecipe),
              backgroundColor: _accentColor,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _getAppBarTitle() {
    if (_userRole == 'admin') {
      switch (_currentIndex) {
        case 0:
          return 'Recipe Management';
        case 1:
          return 'Favorites';
        case 2:
          return 'Meal Plan';
        case 3:
          return 'Profile';
        default:
          return 'Admin Dashboard';
      }
    } else {
      switch (_currentIndex) {
        case 0:
          return 'Recipes';
        case 1:
          return 'Favorites';
        case 2:
          return 'Meal Plan';
        case 3:
          return 'Profile';
        default:
          return 'Home';
      }
    }
  }
}

class _RecipeManagementScreen extends StatefulWidget {
  final bool isAdmin;
  const _RecipeManagementScreen({required this.isAdmin});

  @override
  __RecipeManagementScreenState createState() =>
      __RecipeManagementScreenState();
}

class __RecipeManagementScreenState extends State<_RecipeManagementScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Color _primaryColor = const Color(0xFFFFC107); // Amber 500
  final Color _secondaryColor = const Color(0xFFFFF3E0); // Amber 50
  final Color _accentColor = const Color(0xFFFFA000); // Amber 700
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Vegetarian',
    'Vegan',
    'Quick Meals'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> _filterRecipesByCategoryAndSearch(List<Recipe> recipes) {
    // First filter by category
    List<Recipe> filteredRecipes = _selectedCategory == 'All'
        ? recipes
        : recipes
            .where((recipe) => recipe.category == _selectedCategory)
            .toList();

    // Then filter by search query if it exists
    if (_searchQuery.isNotEmpty) {
      filteredRecipes = filteredRecipes.where((recipe) {
        return recipe.title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            recipe.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filteredRecipes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Welcome title
            Text(
              widget.isAdmin ? 'Welcome Admin!' : 'Discover Recipes',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isAdmin ? 'Manage your recipes' : 'Find your next meal',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
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
            const SizedBox(height: 24),

            // Recommended section
            Text(
              'Recommended',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: StreamBuilder<List<Recipe>>(
                stream: RecipeService()
                    .getRecommendedRecipes(), // Use the new method here
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: _accentColor),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading recommended recipes',
                          style: TextStyle(color: Colors.red)),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text('No recommended recipes yet',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }

                  final recommendedRecipes = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: recommendedRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recommendedRecipes[index];
                      return _buildRecommendedCard(recipe, isDarkMode);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Categories section
            Text(
              'Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : 'All';
                        });
                      },
                      selectedColor: _accentColor,
                      backgroundColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      labelStyle: TextStyle(
                        color: _selectedCategory == category
                            ? Colors.white
                            : isDarkMode
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // All recipes section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Recipes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.allRecipe,
                      arguments: _selectedCategory,
                    );
                  },
                  child: Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 16,
                      color: _accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 225,
              child: StreamBuilder<List<Recipe>>(
                stream: RecipeService().getRecipes(),
                builder: (context, snapshot) {
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: _accentColor),
                    );
                  }

                 final recipes =
                      _filterRecipesByCategoryAndSearch(snapshot.data!);


                  if (recipes.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'No recipes found matching your search'
                            : 'No recipes available in this category',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }

                  
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return widget.isAdmin
                          ? _buildAdminRecipeCard(recipe, isDarkMode)
                          : _buildUserRecipeCard(recipe, isDarkMode);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedCard(Recipe recipe, bool isDarkMode) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: recipe.imageUrl != null
                    ? Image.network(
                        recipe.imageUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 100,
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        child: Icon(Icons.photo,
                            size: 40, color: Colors.grey[400]),
                      ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: _accentColor),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.cookingTime} mins',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminRecipeCard(Recipe recipe, bool isDarkMode) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with tap for details
            InkWell(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RecipeDetailScreen(recipeId: recipe.id),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: recipe.imageUrl != null
                    ? Image.network(
                        recipe.imageUrl!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 100,
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        child: Icon(Icons.photo,
                            size: 40, color: Colors.grey[400]),
                      ),
              ),
            ),
            // Content area
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Action buttons row (only for admin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        color: _accentColor,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.addRecipe,
                          arguments: recipe,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red[400],
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Recipe'),
                              content: const Text(
                                  'Are you sure you want to delete this recipe?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Cancel',
                                      style: TextStyle(color: _accentColor)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            RecipeService().deleteRecipe(recipe.id);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRecipeCard(Recipe recipe, bool isDarkMode) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: recipe.imageUrl != null
                    ? Image.network(
                        recipe.imageUrl!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 100,
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        child: Icon(Icons.photo,
                            size: 40, color: Colors.grey[400]),
                      ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: _accentColor),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.cookingTime} mins',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
