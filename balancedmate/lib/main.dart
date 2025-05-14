import 'package:balanced_meal/core/auth_wrapper.dart';
import 'package:balanced_meal/core/routes.dart';
import 'package:balanced_meal/screens/admin/add_edit_recipe_screen.dart'; // Add this import
import 'package:balanced_meal/screens/login_screen.dart';
import 'package:balanced_meal/screens/auth/register_screen.dart';
import 'package:balanced_meal/screens/recipe_detail_screen.dart';
import 'package:balanced_meal/screens/user/user_home_screen.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food App',
      theme: ThemeData(useMaterial3: true),
      home: const AuthWrapper(),
      routes: {
        AppRoutes.login: (context) =>  LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.recipeDetail: (context) => RecipeDetailScreen(
              recipeId: ModalRoute.of(context)!.settings.arguments as String,
            ),
        AppRoutes.addRecipe: (context) => const AddEditRecipeScreen(),
      },
    );
  }
}
