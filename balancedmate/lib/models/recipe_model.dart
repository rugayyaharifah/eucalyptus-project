// lib/models/recipe_model.dart
class Recipe {
  final String id;
  final String title;
  final String description;
  final String? imageUrl; // Will use ImgBB URLs later
  final int cookingTime;
  final List<String> ingredients;
  final List<String> steps;
  final String creatorId;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.cookingTime,
    required this.ingredients,
    required this.steps,
    required this.creatorId,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      cookingTime: map['cookingTime'],
      ingredients: List<String>.from(map['ingredients']),
      steps: List<String>.from(map['steps']),
      creatorId: map['creatorId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'cookingTime': cookingTime,
      'ingredients': ingredients,
      'steps': steps,
      'creatorId': creatorId,
    };
  }
}
