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
  bool _isLoading = false;
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

  String _recommendationStatus = 'none';

  String _selectedCategory = 'All'; // Add this
  final List<String> _categories = [
    // Add your categories
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Vegetarian',
    'Vegan',
    'Quick Meals'
  ];

  @override
  void initState() {
    if (widget.recipe != null) {
      _titleController.text = widget.recipe!.title;
      _descriptionController.text = widget.recipe!.description;
      _cookingTimeController.text = widget.recipe!.cookingTime.toString();
      _ingredients.addAll(widget.recipe!.ingredients);
      _steps.addAll(widget.recipe!.steps);
      _selectedCategory = widget.recipe!.category;
      _recommendationStatus = widget.recipe!.recommended ? 'recommend' : 'none';
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

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _addStep() {
    if (_stepsController.text.isNotEmpty) {
      setState(() {
        _steps.add(_stepsController.text);
        _stepsController.clear();
      });
    }
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  Future<void> _submitRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true); 
    try {
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
      category: _selectedCategory,
      recommended: _recommendationStatus == 'recommend',
    );

    await RecipeService().addRecipe(recipe);
    if (!mounted) return;
    Navigator.pop(context);
    } catch (e){
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Stop loading
      }
    }

   
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recipe == null ? 'Add Recipe' : 'Edit Recipe',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickAndUploadImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : widget.recipe?.imageUrl != null
                            ? Image.network(
                                widget.recipe!.imageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderImage(isDark),
                              )
                            : _buildPlaceholderImage(isDark),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(_titleController, 'Recipe Title', isDark),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Description', isDark,
                  maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField(
                  _cookingTimeController, 'Cooking Time (minutes)', isDark,
                  keyboardType: TextInputType.number, validator: (value) {
                if (value!.isEmpty) return 'Please enter cooking time';
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              }),
               const SizedBox(height: 16),
              // Add Category Dropdown
              _buildCategoryDropdown(isDark),
                             const SizedBox(height: 16),

              _buildRecommendationDropdown(isDark),
              const SizedBox(height: 24),
              _buildSectionLabel('Ingredients', isDark),
              _buildListSection(_ingredients, _removeIngredient, isDark),
              _buildAddField(_ingredientsController, 'Add ingredient',
                  _addIngredient, isDark),
              const SizedBox(height: 24),
              _buildSectionLabel('Steps', isDark),
              _buildListSection(_steps, _removeStep, isDark, isStep: true),
              _buildAddField(_stepsController, 'Add step', _addStep, isDark,
                  maxLines: 2),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : _submitRecipe, // Disable when loading
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.recipe == null
                              ? 'Add Recipe'
                              : 'Update Recipe',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildRecommendationDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSectionLabel('Recommendation', isDark),
        DropdownButtonFormField<String>(
          value: _recommendationStatus,
          decoration: InputDecoration(
            labelText: 'Recommend this recipe?',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: const [
            DropdownMenuItem(
              value: 'none',
              child: Text('None'),
            ),
            DropdownMenuItem(
              value: 'recommend',
              child: Text('Recommend'),
            ),
          ],
          onChanged: (String? newValue) {
            setState(() => _recommendationStatus = newValue!);
          },
        ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, bool isDark,
      {int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator ?? (value) => value!.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildListSection(
      List<String> items, Function(int) onRemove, bool isDark,
      {bool isStep = false}) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text('No ${isStep ? "steps" : "ingredients"} added yet'),
      );
    }
    return Column(
      children: items.asMap().entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: isStep
                ? CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: Text('${entry.key + 1}',
                        style: const TextStyle(color: Colors.white)),
                  )
                : null,
            title: Text(entry.value),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => onRemove(entry.key),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddField(TextEditingController controller, String label,
      VoidCallback onAdd, bool isDark,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: IconButton(
          icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
          onPressed: onAdd,
        ),
      ),
      onFieldSubmitted: (_) => onAdd(),
    );
  }

  Widget _buildPlaceholderImage(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text('Tap to add image', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: _categories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCategory = newValue!;
        });
      },
      validator: (value) => value == null ? 'Please select a category' : null,
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
