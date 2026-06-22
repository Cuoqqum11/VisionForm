import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import '../models/diet_models.dart';

class DietLogic extends ChangeNotifier {
  // ── Profile ──────────────────────────────────────────────────────────────
  final UserDietProfile profile = UserDietProfile();

  // ── Flow state ───────────────────────────────────────────────────────────
  DietFlowState _state = DietFlowState.entry;
  DietFlowState get state => _state;

  // ── Ingredient review ────────────────────────────────────────────────────
  XFile? _pickedImage;
  XFile? get pickedImage => _pickedImage;

  // All detected ingredients; key = name, value = enabled (shown as chip)
  final Map<String, bool> _ingredients = {};
  List<String> get allIngredients => _ingredients.keys.toList();
  List<String> get confirmedIngredients =>
      _ingredients.entries.where((e) => e.value).map((e) => e.key).toList();

  bool isIngredientEnabled(String name) => _ingredients[name] ?? true;

  void toggleIngredient(String name) {
    if (_ingredients.containsKey(name)) {
      _ingredients[name] = !_ingredients[name]!;
      notifyListeners();
    }
  }

  void addIngredient(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _ingredients[trimmed] = true;
    notifyListeners();
  }

  void removeIngredient(String name) {
    _ingredients.remove(name);
    notifyListeners();
  }

  // ── Results ───────────────────────────────────────────────────────────────
  List<MealSuggestion> _meals = [];
  List<MealSuggestion> get meals => _meals;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Saved meals (in-memory for MVP) ───────────────────────────────────────
  final List<SavedMeal> _savedMeals = [
    const SavedMeal(name: 'Egg fried rice', tag: 'High protein', calories: 420),
    const SavedMeal(name: 'Chicken bowl', tag: 'Goal match', calories: 510),
    const SavedMeal(name: 'Greek salad', tag: 'Low carb', calories: 290),
  ];
  List<SavedMeal> get savedMeals => List.unmodifiable(_savedMeals);

  void saveMeal(MealSuggestion meal) {
    final already = _savedMeals.any((s) => s.name == meal.name);
    if (!already) {
      _savedMeals.insert(
        0,
        SavedMeal(name: meal.name, tag: meal.tag, calories: meal.calories),
      );
      notifyListeners();
    }
  }

  // ── Profile setters ───────────────────────────────────────────────────────
  void setGoal(String goal) {
    profile.goal = goal;
    notifyListeners();
  }

  void setDietType(String dietType) {
    profile.dietType = dietType;
    notifyListeners();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────
  void goToEntry() {
    _state = DietFlowState.entry;
    _pickedImage = null;
    _ingredients.clear();
    _meals = [];
    _errorMessage = null;
    notifyListeners();
  }

  void goToResult() {
    _state = DietFlowState.result;
    notifyListeners();
  }

  // ── Step 1: Pick image & detect ingredients ───────────────────────────────
  Future<void> scanFridge({bool fromCamera = true}) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (file == null) return; // user cancelled

    _pickedImage = file;
    _ingredients.clear();
    _state = DietFlowState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final imageBytes = await file.readAsBytes();

      final parts = [
        Part.text(
          'Look at this fridge or ingredients photo and list every individual '
          'food item or ingredient you can see. '
          'Return ONLY a JSON array of strings, each item being a single '
          'ingredient name. Example: ["eggs","milk","spinach","chicken breast"]. '
          'No extra text, no markdown fences.',
        ),
        Part.inline(
          InlineData(mimeType: 'image/jpeg', data: base64Encode(imageBytes)),
        ),
      ];

      final response = await Gemini.instance.prompt(parts: parts);
      final raw = response?.output?.trim() ?? '[]';

      // Strip accidental markdown fences if present
      final cleaned = raw
          .replaceAll(RegExp(r'^```json?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```$', multiLine: true), '')
          .trim();

      final List<dynamic> list = jsonDecode(cleaned) as List<dynamic>;
      for (final item in list) {
        final name = item.toString().trim();
        if (name.isNotEmpty) _ingredients[name] = true;
      }

      _state = DietFlowState.review;
    } catch (e) {
      // Fallback: go to review with empty list so user can add manually
      _state = DietFlowState.review;
    }

    notifyListeners();
  }

  // ── Step 2: Get meal recommendations ─────────────────────────────────────
  Future<void> getMealRecommendations() async {
    if (confirmedIngredients.isEmpty) return;

    _state = DietFlowState.loading;
    _errorMessage = null;
    notifyListeners();

    final prompt =
        '''
You are a fitness nutrition coach. Based on the information below, suggest 3 meals.
 
User goal: ${profile.goal}
Diet type: ${profile.dietType}
Favourite foods: ${profile.favoriteFoods.join(', ')}
Available ingredients: ${confirmedIngredients.join(', ')}
 
For EACH meal return:
- name: short meal name
- usedIngredients: array of strings from the available list used
- calories: integer (total kcal)
- macros: object with integer fields protein, carbs, fat (all in grams)
- tag: exactly ONE of: "High protein", "Low carb", "Goal match", "Quick & easy", "Vegetarian", "Keto", "Balanced"
- steps: array of 4-6 plain English cooking instruction strings (no numbering, just the sentence)
 
Respond ONLY with a valid JSON array of 3 meal objects. No preamble, no markdown fences.
''';

    try {
      final response = await Gemini.instance.prompt(parts: [Part.text(prompt)]);

      final raw = response?.output?.trim() ?? '[]';
      final cleaned = raw
          .replaceAll(RegExp(r'^```json?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```$', multiLine: true), '')
          .trim();

      final List<dynamic> list = jsonDecode(cleaned) as List<dynamic>;
      _meals = list
          .map((json) => MealSuggestion.fromJson(json as Map<String, dynamic>))
          .toList();

      _state = DietFlowState.result;
    } catch (e) {
      _errorMessage = 'Could not generate meals. Please try again.';
      _state = DietFlowState.error;
    }

    notifyListeners();
  }
}
