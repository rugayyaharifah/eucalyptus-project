// lib/screens/meal_planner_screen.dart
import 'package:balanced_meal/core/routes.dart';
import 'package:balanced_meal/models/recipe_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:balanced_meal/models/meal_plan_model.dart';
import 'package:balanced_meal/services/meal_plan_service.dart';
import 'package:balanced_meal/services/recipe_service.dart';
import 'package:intl/intl.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  late DateTime _currentWeekStart;
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getStartOfWeek(DateTime.now());
  }

  DateTime _getStartOfWeek(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return normalizedDate.subtract(Duration(days: normalizedDate.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: StreamBuilder<List<MealPlan>>(
        stream: MealPlanService().getCurrentWeekMealPlans(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: \${snapshot.error}',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child:
                  CircularProgressIndicator(color: theme.colorScheme.primary),
            );
          }

          final mealPlanMap = {
            for (var plan in snapshot.data!)
              DateFormat('yyyy-MM-dd').format(plan.date): plan
          };

          return ListView.builder(
            itemCount: 7,
            itemBuilder: (context, dayIndex) {
              final currentDate =
                  _currentWeekStart.add(Duration(days: dayIndex));
              final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);
              final dayPlan = mealPlanMap[dateKey] ??
                  MealPlan(
                    id: '${userId}_$dateKey', 
                    userId: userId,
                    date: currentDate,
                    meals: {
                      for (var mealType in _mealTypes)
                        mealType.toLowerCase(): MealEntry(name: '')
                    },
                  );
              return _buildDayCard(context, currentDate, dayPlan);
            },
          );
        },
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, DateTime date, MealPlan dayPlan) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('EEEE').format(date),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d').format(date),
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._mealTypes.map((mealType) {
              final mealEntry =
                  dayPlan.meals[mealType.toLowerCase()] ?? MealEntry(name: '');
              return _buildMealRow(context, mealType, mealEntry, dayPlan, date);
            }).toList(),
          ],
        ),
      ),
    );
  }

 Widget _buildMealRow(BuildContext context, String mealType,
    MealEntry mealEntry, MealPlan dayPlan, DateTime date) {
  final theme = Theme.of(context);
  final isEmpty = mealEntry.name.isEmpty;

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: isEmpty
          ? theme.colorScheme.surfaceVariant
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showMealEditor(mealType.toLowerCase(), dayPlan, date),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 80,
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                mealType,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                isEmpty ? 'Tap to add meal' : mealEntry.name,
                style: TextStyle(
                  color: isEmpty
                      ? theme.colorScheme.onSurface.withOpacity(0.6)
                      : null,
                ),
                overflow: TextOverflow
                    .ellipsis, // This adds the "..." when text is too long
                maxLines: 1,
              ),
            ),
            if (!isEmpty) ...[
              if (mealEntry.recipeId != null)
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  color: Colors.blue,
                  onPressed: () async {
                    try {
                      final recipe = await RecipeService()
                          .getRecipeById(mealEntry.recipeId!);
                      if (!mounted) return;
                      Navigator.pushNamed(
                        context,
                        AppRoutes.recipeDetail,
                        arguments: recipe.id,
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Recipe no longer exists'),
                          backgroundColor: theme.colorScheme.error,
                        ),
                      );
                    }
                  },
                ),
              Icon(Icons.edit,
                  size: 18, color: theme.iconTheme.color?.withOpacity(0.5)),
            ],
          ]
        ),
      ),
    ),
  );
}

  Future<void> _showMealEditor(
        String mealType, MealPlan dayPlan, DateTime date) async {
    final theme = Theme.of(context);
    final recipeService = RecipeService();
    final favoriteRecipes =
        await recipeService.getFavoriteRecipes(dayPlan.userId);
    final mealEntry = dayPlan.meals[mealType] ?? MealEntry(name: '');
    final nameController = TextEditingController(text: mealEntry.name);
    final notesController = TextEditingController(text: mealEntry.notes ?? '');
    String? selectedRecipeId = mealEntry.recipeId;

    // Get the currently selected recipe details if it exists but isn't in favorites
    Recipe? currentRecipe;
    if (selectedRecipeId != null &&
        !favoriteRecipes.any((r) => r.id == selectedRecipeId)) {
      try {
        currentRecipe = await recipeService.getRecipeById(selectedRecipeId!);
      } catch (e) {
        // Recipe might not exist anymore
        selectedRecipeId = null;
      }
    }
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              title: Text(
                '${mealType.capitalize()} for ${DateFormat('EEEE').format(date)}',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Meal Name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: theme.colorScheme.primary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true, 
                      value: selectedRecipeId,
                      decoration: InputDecoration(
                        labelText: 'Link to Recipe (Optional)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: theme.colorScheme.primary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('None')),
                        if (currentRecipe != null)
                          DropdownMenuItem(
                            value: currentRecipe.id,
                            child:
                                SizedBox(
                                  width: 200,
                                  child: Text('${currentRecipe.title}', overflow: TextOverflow
                                  .ellipsis, // This adds the "..." when text is too long
                              maxLines: 1,
                                )
                            ),
                          ),
                        ...favoriteRecipes.map((recipe) {
                          return DropdownMenuItem(
                            value: recipe.id,
                            child: Text(recipe.title, overflow: TextOverflow
                                  .ellipsis, // This adds the "..." when text is too long
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedRecipeId = value;
                          if (value != null) {
                            // Find the recipe in either favorites or current recipe
                            final recipe = favoriteRecipes.firstWhere(
                              (r) => r.id == value,
                              orElse: () => currentRecipe != null &&
                                      currentRecipe.id == value
                                  ? currentRecipe
                                  : throw Exception('Recipe not found'),
                            );
                            nameController.text = recipe.title;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: theme.colorScheme.primary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: TextStyle(color: theme.colorScheme.primary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updatedEntry = MealEntry(
                      name: nameController.text.trim(),
                      recipeId: selectedRecipeId,
                      notes: notesController.text.trim().isNotEmpty
                          ? notesController.text.trim()
                          : null,
                    );

                    final updatedPlan = MealPlan(
                      id: dayPlan.id,
                      userId: dayPlan.userId,
                      date: dayPlan.date,
                      meals: {...dayPlan.meals}..[mealType] = updatedEntry,
                    );

                    await MealPlanService().saveMealPlan(updatedPlan);
                    if (!mounted) return;
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Meal updated successfully'),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    );

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
