// lib/screens/home_all_screen.dart
import 'package:balanced_meal/screens/favorites_screen.dart';
import 'package:balanced_meal/screens/meal_planner_screen.dart';
import 'package:balanced_meal/screens/profile_screen.dart';
import 'package:balanced_meal/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:balanced_meal/core/routes.dart';
import 'package:balanced_meal/models/recipe_model.dart';
import 'package:balanced_meal/services/recipe_service.dart';
import 'package:balanced_meal/screens/recipe_detail/recipe_detail_screen.dart';

class HomeAllScreen extends StatefulWidget {

  const HomeAllScreen({super.key});

  @override
  State<HomeAllScreen> createState() => _HomeAllScreenState();
}

class _HomeAllScreenState extends State<HomeAllScreen> {
  int _currentIndex = 0;
  final Color _primaryColor = const Color(0xFFFFC107); // Amber 500
  final Color _secondaryColor = const Color(0xFFFFF3E0); // Amber 50
  final Color _accentColor = const Color(0xFFFFA000); // Amber 700
  String? _userRole;

 
  
  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final role = await AuthService().getUserRole(user.uid);
      setState(() {
        _userRole = role;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Define screens based on user role
    final List<Widget> screens = [
      _RecipeManagementScreen(userRole: _userRole!),
      const FavoritesScreen(),
      const MealPlannerScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      floatingActionButton: _userRole == 'admin'
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
        children: screens,
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
              child: Icon(Icons.restaurant_menu),
            ),
            label: _userRole == 'admin' ? 'Manage' : 'Recipes',
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
              child: Icon(Icons.favorite),
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
              child: Icon(Icons.calendar_month),
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
              child: Icon(Icons.person),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return _userRole == 'admin' ? 'Recipe Management' : 'Recipes';
      case 1:
        return 'Favorites';
      case 2:
        return 'Meal Plan';
      case 3:
        return 'Profile';
      default:
        return _userRole == 'admin' ? 'Admin Dashboard' : 'Home';
    }
  }
}

class _RecipeManagementScreen extends StatefulWidget {
  final String userRole;

  const _RecipeManagementScreen({required this.userRole});

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
  String _selectedCategory = 'All'; // Add this

  // Add your categories list
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

  List<Recipe> _filterRecipes(List<Recipe> recipes) {
    // First filter by category
    List<Recipe> filtered = _selectedCategory == 'All'
        ? recipes
        : recipes.where((r) => r.category == _selectedCategory).toList();

    // Then filter by search query if it exists
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((recipe) {
        return recipe.title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            recipe.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
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
        ),
        
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 16, bottom: 8),
          child: SizedBox(
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
        ),
        Expanded(
          child: StreamBuilder<List<Recipe>>(
            stream: RecipeService().getRecipes(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(color: _accentColor),
                );
              }

              final recipes = _filterRecipes(snapshot.data!);

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

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.5,
                ),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return widget.userRole == 'admin'
                      ? Dismissible(
                          key: Key(recipe.id),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.red[900]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: Icon(Icons.delete,
                                color: isDarkMode
                                    ? Colors.red[100]
                                    : Colors.red[800]),
                          ),
                          secondaryBackground: Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.blue[900]
                                  : Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: Icon(Icons.edit,
                                color: isDarkMode
                                    ? Colors.blue[100]
                                    : Colors.blue[800]),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              Navigator.pushNamed(context, AppRoutes.addRecipe,
                                  arguments: recipe);
                              return false;
                            } else {
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Recipe'),
                                  content: const Text(
                                      'Are you sure you want to delete this recipe?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text('Cancel',
                                          style:
                                              TextStyle(color: _accentColor)),
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
                            }
                          },
                          onDismissed: (direction) {
                            if (direction == DismissDirection.startToEnd) {
                              RecipeService().deleteRecipe(recipe.id);
                            }
                          },
                          child: _buildRecipeCard(recipe, isDarkMode, context),
                        )
                      : _buildRecipeCard(recipe, isDarkMode, context);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(
      Recipe recipe, bool isDarkMode, BuildContext context) {
    return Card(
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
              child: Stack(
                children: [
                  recipe.imageUrl != null
                      ? Image.network(
                          recipe.imageUrl!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return SizedBox(
                              height: 140,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                      : null,
                                  color: _primaryColor,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 140,
                            color: isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            child: Icon(Icons.broken_image,
                                color: Colors.grey[400]),
                          ),
                        )
                      : Container(
                          height: 140,
                          width: double.infinity,
                          color:
                              isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          child: Center(
                            child: Icon(Icons.photo,
                                size: 50, color: Colors.grey[400]),
                          ),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.cookingTime} mins',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Description
                  SizedBox(
                    height: 40,
                    child: Text(
                      recipe.description,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Action buttons (only for admin)
                  if (widget.userRole == 'admin')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color:
                                isDarkMode ? Colors.grey[800] : _secondaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit,
                                    size: 20, color: _accentColor),
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.addRecipe,
                                  arguments: recipe,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    size: 20,
                                    color: isDarkMode
                                        ? Colors.red[300]
                                        : Colors.red[400]),
                                onPressed: () async {
                                  final confirm = await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Recipe'),
                                      content: const Text(
                                          'Are you sure you want to delete this recipe?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text('Cancel',
                                              style: TextStyle(
                                                  color: _accentColor)),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
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
}
