import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';

class AddEditRecipeScreen extends StatefulWidget {
  final Recipe? recipe;
  const AddEditRecipeScreen({super.key, this.recipe});

  @override
  State<AddEditRecipeScreen> createState() => _AddEditRecipeScreenState();
}

class _AddEditRecipeScreenState extends State<AddEditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cookingTimeController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _stepsController = TextEditingController();
  File? _selectedImage;
  final _picker = ImagePicker();
  final List<String> _ingredients = [];
  final List<String> _steps = [];

  @override
  void initState() {
    if (widget.recipe != null) {
      _titleController.text = widget.recipe!.title;
      _descriptionController.text = widget.recipe!.description;
      _cookingTimeController.text = widget.recipe!.cookingTime.toString();
      _ingredients.addAll(widget.recipe!.ingredients);
      _steps.addAll(widget.recipe!.steps);
    }
    super.initState();
  }

  Future<void> _pickAndUploadImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _selectedImage = File(image.path));
  }

  void _addIngredient() {
    if (_ingredientsController.text.isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientsController.text);
        _ingredientsController.clear();
      });
    }
  }

  void _addStep() {
    if (_stepsController.text.isNotEmpty) {
      setState(() {
        _steps.add(_stepsController.text);
        _stepsController.clear();
      });
    }
  }

  Future<void> _submitRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await RecipeService().uploadImageAndGetUrl(_selectedImage!);
    }

    final recipe = Recipe(
      id: widget.recipe?.id ?? const Uuid().v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      imageUrl: imageUrl ?? widget.recipe?.imageUrl,
      cookingTime: int.parse(_cookingTimeController.text),
      ingredients: _ingredients,
      steps: _steps,
      creatorId: FirebaseAuth.instance.currentUser!.uid,
    );

    await RecipeService().addRecipe(recipe);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.recipe == null ? 'Add Recipe' : 'Edit Recipe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickAndUploadImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : widget.recipe?.imageUrl != null
                          ? Image.network(widget.recipe!.imageUrl!,
                              fit: BoxFit.cover)
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 50),
                                Text('Tap to add image'),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Recipe Title'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Cooking Time
              TextFormField(
                controller: _cookingTimeController,
                decoration:
                    const InputDecoration(labelText: 'Cooking Time (minutes)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Ingredients
              const Text('Ingredients',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ..._ingredients.map((ing) => ListTile(
                    title: Text(ing),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => setState(() => _ingredients.remove(ing)),
                    ),
                  )),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ingredientsController,
                      decoration:
                          const InputDecoration(labelText: 'Add Ingredient'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addIngredient,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Steps
              const Text('Steps',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ..._steps.asMap().entries.map((entry) => ListTile(
                    leading: Text('${entry.key + 1}.'),
                    title: Text(entry.value),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () =>
                          setState(() => _steps.removeAt(entry.key)),
                    ),
                  )),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stepsController,
                      decoration: const InputDecoration(labelText: 'Add Step'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addStep,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _submitRecipe,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Save Recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cookingTimeController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    super.dispose();
  }
}
