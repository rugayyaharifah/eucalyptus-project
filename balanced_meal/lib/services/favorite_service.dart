// lib/services/favorite_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addFavorite(String userId, String recipeId) async {
    try {
      await _firestore
          .collection('userFavorites')
          .doc(userId)
          .collection('favorites')
          .doc(recipeId)
          .set({'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error adding favorite: $e');
      rethrow;
    }
  }

  Future<void> removeFavorite(String userId, String recipeId) async {
    try {
      await _firestore
          .collection('userFavorites')
          .doc(userId)
          .collection('favorites')
          .doc(recipeId)
          .delete();
    } catch (e) {
      debugPrint('Error removing favorite: $e');
      rethrow;
    }
  }

  Future<bool> isFavorite(String userId, String recipeId) async {
    try {
      final doc = await _firestore
          .collection('userFavorites')
          .doc(userId)
          .collection('favorites')
          .doc(recipeId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking favorite: $e');
      return false;
    }
  }

  Stream<bool> isFavoriteStream(String userId, String recipeId) {
    return _firestore
        .collection('userFavorites')
        .doc(userId)
        .collection('favorites')
        .doc(recipeId)
        .snapshots()
        .map((doc) => doc.exists)
        .handleError((e) {
      debugPrint('Stream error for favorite: $e');
      return false;
    });
  }

  Stream<List<String>> getUserFavorites(String userId) {
    return _firestore
        .collection('userFavorites')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList())
        .handleError((e) {
      debugPrint('Error getting user favorites: $e');
      return [];
    });
  }
}
