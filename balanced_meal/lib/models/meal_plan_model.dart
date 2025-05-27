// lib/models/meal_plan_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MealPlan {
  final String id;
  final String userId;
  final DateTime date;
  final Map<String, MealEntry> meals; // {'breakfast': MealEntry, ...}

  MealPlan({
    required this.id,
    required this.userId,
    required this.date,
    required this.meals,
  });

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      id: map['id'],
      userId: map['userId'],
      date: (map['date'] as Timestamp).toDate(),
      meals: (map['meals'] as Map)
          .map((key, value) => MapEntry(key, MealEntry.fromMap(value))),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'meals': meals.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}

class MealEntry {
  final String name;
  final String? recipeId;
  final String? notes;

  MealEntry({
    required this.name,
    this.recipeId,
    this.notes,
  });

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      name: map['name'],
      recipeId: map['recipeId'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (recipeId != null) 'recipeId': recipeId,
      if (notes != null) 'notes': notes,
    };
  }
}
