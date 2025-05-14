// lib/services/recipe_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:balanced_meal/models/recipe_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  get http => null;

  // Add new recipe
  Future<void> addRecipe(Recipe recipe) async {
    await _firestore.collection('recipes').doc(recipe.id).set(recipe.toMap());
  }

  // Get all recipes (for home screen)
  Stream<List<Recipe>> getRecipes() {
    return _firestore.collection('recipes').orderBy('title').snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList());
  }

  // Admin-only: Delete recipe
  Future<void> deleteRecipe(String id) async {
    await _firestore.collection('recipes').doc(id).delete();
  }

  Future<String?> uploadImageAndGetUrl(File image) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = dotenv.env['IMGBB_API_KEY']!
        ..files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final json = await response.stream.bytesToString();
      return jsonDecode(json)['data']['url']; // Returns CDN URL
    } catch (e) {
      debugPrint('Image upload failed: $e');
      return null;
    }
  }
}
