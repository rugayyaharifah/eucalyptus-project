import 'package:balanced_meal/core/auth_wrapper.dart';
import 'package:balanced_meal/core/routes.dart';
import 'package:balanced_meal/core/theme_provider.dart'; // Add this import
import 'package:balanced_meal/models/recipe_model.dart';
import 'package:balanced_meal/screens/admin/addedit_recipe.dart';
import 'package:balanced_meal/screens/home_all_screen.dart';
import 'package:balanced_meal/screens/home_screen.dart';
import 'package:balanced_meal/screens/favorites_screen.dart';
import 'package:balanced_meal/screens/login_screen.dart';
import 'package:balanced_meal/screens/auth/register_screen.dart';
import 'package:balanced_meal/screens/meal_planner_screen.dart';
import 'package:balanced_meal/screens/recipe_detail/recipe_detail_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  // Changed to ConsumerWidget
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Food App',
      theme: theme, // Use the theme from provider
      darkTheme: theme, // We're handling dark/light ourselves
      themeMode: ThemeMode.system, // Fallback if needed
      home: const AuthWrapper(),
      routes: {
        AppRoutes.login: (context) =>  LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.recipeDetail: (context) => RecipeDetailScreen(
              recipeId: ModalRoute.of(context)!.settings.arguments as String,
            ),
        AppRoutes.addRecipe: (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          return AddEditRecipeScreen(recipe: args as Recipe?);
        },
        AppRoutes.favorite: (context) => const FavoritesScreen(),
        AppRoutes.mealPlan: (context) => const MealPlannerScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.allRecipe: (context) => const HomeAllScreen(),
      },
    );
  }
}
