// lib/models/recipe_model.dart
class Recipe {
  final String id;
  final String title;
  final String description;
  final String? imageUrl; 
  final int cookingTime;
  final List<String> ingredients;
  final List<String> steps;
  final String creatorId;
   final String category;
   final bool recommended;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.cookingTime,
    required this.ingredients,
    required this.steps,
    required this.creatorId,
    this.category = 'All',
    this.recommended = false,
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
      category: map['category'] ?? 'All',
      recommended: map['recommended'] ?? false,
      
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
      'category': category,
      'recommended': recommended,
    };
  }
}
