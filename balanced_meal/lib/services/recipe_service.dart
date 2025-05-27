// lib/services/recipe_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:balanced_meal/models/recipe_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// lib/services/cloudinary_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Replace with your actual cloud name and preset
  static const String _cloudName = 'drziiurke';
  static const String _uploadPreset = 'flutter_uploads'; // Your preset name

  

  Future<String?> uploadImage(File image) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      debugPrint('Uploading image to Cloudinary...');
      final response = await request.send();

      if (response.statusCode == 200) {
        final json = await response.stream.bytesToString();
        final data = jsonDecode(json);
        debugPrint('Upload successful: ${data['secure_url']}');
        return data['secure_url'];
      } else {
        final error = await response.stream.bytesToString();
        debugPrint('Upload failed (${response.statusCode}): $error');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }
}

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Add new recipe
  Future<void> addRecipe(Recipe recipe) async {
    await _firestore.collection('recipes').doc(recipe.id).set(recipe.toMap());
  }

  Stream<List<Recipe>> getRecipesByCategory(String category) {
    if (category == 'All') {
      return _firestore.collection('recipes').orderBy('title').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList());
    } else {
      return _firestore
          .collection('recipes')
          .where('category', isEqualTo: category)
          .orderBy('title')
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList());
    }
  }

  Stream<List<Recipe>> getRecommendedRecipes() {
    return _firestore
        .collection('recipes')
        .where('recommended', isEqualTo: true)
        .orderBy('title')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList());
  }

  // Get all recipes (for home screen)
  Stream<List<Recipe>> getRecipes() {
    return _firestore.collection('recipes').orderBy('title').snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => Recipe.fromMap(doc.data())).toList());
  }

  Future<Recipe?> getRecipe(String id) async {
    try {
      final doc = await _firestore.collection('recipes').doc(id).get();
      return doc.exists ? Recipe.fromMap(doc.data()!) : null;
    } catch (e) {
      debugPrint('Error getting recipe: $e');
      return null;
    }
  }

  Future<List<Recipe>> getFavoriteRecipes(String userId) async {
    try {
      // First get the favorite recipe IDs
      final favoritesSnapshot = await _firestore
          .collection('userFavorites')
          .doc(userId)
          .collection('favorites')
          .get();

      if (favoritesSnapshot.docs.isEmpty) return [];

      // Then fetch each recipe
      final recipes = await Future.wait(
          favoritesSnapshot.docs.map((doc) => getRecipe(doc.id)));

      // Filter out any null values and return
      return recipes.whereType<Recipe>().toList();
    } catch (e) {
      debugPrint('Error fetching favorite recipes: $e');
      return [];
    }
  }

  // Admin-only: Delete recipe
  Future<void> deleteRecipe(String id) async {
    await _firestore.collection('recipes').doc(id).delete();
  }

  Future<String?> uploadImageAndGetUrl(File image) async {
    return await _cloudinaryService.uploadImage(image);
  }
}
