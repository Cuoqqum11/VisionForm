import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import '../models/diet_models.dart';
import '../database/diet_database_service.dart';
 
class DietLogic extends ChangeNotifier {
  // ── Profile ──────────────────────────────────────────────────────────────
  final UserDietProfile profile = UserDietProfile();
 
  // ── Flow state ───────────────────────────────────────────────────────────
  DietFlowState _state = DietFlowState.entry;
  DietFlowState get state => _state;
 
  // ── Ingredient review ────────────────────────────────────────────────────
  XFile? _pickedImage;
  XFile? get pickedImage => _pickedImage;
 
  // All detected ingredients; key = name, value = checked (included)
  final Map<String, bool> _ingredients = {};
  List<String> get allIngredients => _ingredients.keys.toList();
  List<String> get confirmedIngredients =>
      _ingredients.entries.where((e) => e.value).map((e) => e.key).toList();
 
  bool isIngredientChecked(String name) => _ingredients[name] ?? true;
 
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
 
  // ── Meal list (phase 1: names + macros, no steps yet) ─────────────────────
  List<MealSuggestion> _meals = [];
  List<MealSuggestion> get meals => _meals;
 
  // ── Selected meal (phase 2: instructions matched to it) ───────────────────
  MealSuggestion? _selectedMeal;
  MealSuggestion? get selectedMeal => _selectedMeal;
 
  bool _selectedMealLogged = false;
  bool get selectedMealLogged => _selectedMealLogged;
 
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
 
  // ── Saved meals (in-memory for MVP) ───────────────────────────────────────
  final List<SavedMeal> _savedMeals = [
    const SavedMeal(
      name: 'Egg fried rice',
      tag: 'High protein',
      calories: 420,
      protein: 24,
      carbs: 52,
      fat: 12,
    ),
    const SavedMeal(
      name: 'Chicken bowl',
      tag: 'Goal match',
      calories: 510,
      protein: 38,
      carbs: 44,
      fat: 16,
    ),
    const SavedMeal(
      name: 'Greek salad',
      tag: 'Low carb',
      calories: 290,
      protein: 12,
      carbs: 18,
      fat: 19,
    ),
  ];
  List<SavedMeal> get savedMeals => List.unmodifiable(_savedMeals);
 
  // Tracks which saved meals have already been logged today, just so the
  // entry screen can show a quick "Logged" state instead of letting the
  // user spam-tap duplicate entries by accident.
  final Set<String> _loggedSavedMealNames = {};
  bool isSavedMealLoggedToday(String name) =>
      _loggedSavedMealNames.contains(name);
 
  void saveMeal(MealSuggestion meal) {
    final already = _savedMeals.any((s) => s.name == meal.name);
    if (!already) {
      _savedMeals.insert(
        0,
        SavedMeal(
          name: meal.name,
          tag: meal.tag,
          calories: meal.calories,
          protein: meal.macros.protein,
          carbs: meal.macros.carbs,
          fat: meal.macros.fat,
        ),
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
    _selectedMeal = null;
    _selectedMealLogged = false;
    _errorMessage = null;
    notifyListeners();
  }
 
  /// Back from the meal-detail screen to the meal list, without re-querying
  /// Gemini — so the user can try a different one of the 3 suggestions.
  void backToMealList() {
    _state = DietFlowState.mealList;
    _selectedMeal = null;
    _selectedMealLogged = false;
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
          'food item or ingredient you can see, being reasonably generous '
          '(include partially visible or likely items). '
          'Return ONLY a JSON array of strings, each item a single ingredient '
          'name, no quantities, no seasonings (skip salt, pepper, oil, spices). '
          'Example: ["eggs","milk","spinach","chicken breast"]. '
          'No extra text, no markdown fences.',
        ),
        Part.inline(
          InlineData(mimeType: 'image/jpeg', data: base64Encode(imageBytes)),
        ),
      ];
 
      final response = await Gemini.instance.prompt(parts: parts);
      final raw = response?.output?.trim() ?? '[]';
      final cleaned = _stripFences(raw);
 
      final List<dynamic> list = jsonDecode(cleaned) as List<dynamic>;
      for (final item in list) {
        final name = item.toString().trim();
        if (name.isNotEmpty) _ingredients[name] = true;
      }
 
      _state = DietFlowState.review;
    } catch (e) {
      // Fallback: go to review with an empty list so the user can add manually
      _state = DietFlowState.review;
    }
 
    notifyListeners();
  }
 
  // ── Step 2: Generate 3 meal options (names + macros, no steps yet) ────────
  Future<void> getMealRecommendations() async {
    if (confirmedIngredients.isEmpty) return;
 
    _state = DietFlowState.loading;
    _errorMessage = null;
    notifyListeners();
 
    final prompt = '''
You are a fitness nutrition coach. Based on the information below, suggest 3 meals
the user could realistically make.
 
User goal: ${profile.goal}
Diet type: ${profile.dietType}
Favourite foods: ${profile.favoriteFoods.join(', ')}
Ingredients the user has on hand: ${confirmedIngredients.join(', ')}
 
Rules:
- You may assume basic pantry staples are available even if not listed
  (oil, salt, pepper, rice, water, butter).
- You do NOT need to use every listed ingredient in every meal — pick what
  makes a sensible dish.
- It's fine to suggest a meal that only uses a subset of what's available;
  never refuse to generate meals just because the list looks short.
- For usedIngredients, include an approximate amount when you can reasonably
  estimate one, formatted like "chicken breast (150g)" or "egg (2)".
  If you can't estimate an amount, just use the plain ingredient name.
 
For EACH meal return:
- name: short meal name
- usedIngredients: array of strings as described above
- calories: integer (total kcal)
- macros: object with integer fields protein, carbs, fat (all in grams)
- tag: exactly ONE of: "High protein", "Low carb", "Goal match", "Quick & easy", "Vegetarian", "Keto", "Balanced"
 
Do NOT include a "steps" field yet.
Respond ONLY with a valid JSON array of 3 meal objects. No preamble, no markdown fences.
''';
 
    try {
      final response = await Gemini.instance.prompt(parts: [Part.text(prompt)]);
      final raw = response?.output?.trim() ?? '[]';
      final cleaned = _stripFences(raw);
 
      final List<dynamic> list = jsonDecode(cleaned) as List<dynamic>;
      _meals = list
          .map((json) => MealSuggestion.fromJson(json as Map<String, dynamic>))
          .toList();
 
      _state = DietFlowState.mealList;
    } catch (e) {
      _errorMessage = 'Could not generate meals. Please try again.';
      _state = DietFlowState.error;
    }
 
    notifyListeners();
  }
 
  // ── Step 3: User picked one meal — generate matching instructions ─────────
  Future<void> selectMeal(MealSuggestion meal) async {
    _state = DietFlowState.loading;
    _errorMessage = null;
    notifyListeners();
 
    final prompt = '''
You are a cooking assistant. The user wants to make this exact meal:
 
Meal name: ${meal.name}
Ingredients to use: ${meal.usedIngredients.join(', ')}
User goal: ${profile.goal}
Diet type: ${profile.dietType}
 
Write 4 to 6 clear, plain-English cooking steps to make this meal using
those ingredients. Assume the user also has basic seasonings (salt, pepper,
oil, common spices) on hand and naturally fold them into the steps where
appropriate — do not list them as separate ingredients, just mention them
in the instructions (e.g. "season with salt and pepper").
 
Respond ONLY with a valid JSON array of step strings, no numbering, no
preamble, no markdown fences. Example: ["Heat oil in a pan over medium heat.", "..."]
''';
 
    try {
      final response = await Gemini.instance.prompt(parts: [Part.text(prompt)]);
      final raw = response?.output?.trim() ?? '[]';
      final cleaned = _stripFences(raw);
 
      final List<dynamic> rawSteps = jsonDecode(cleaned) as List<dynamic>;
      final steps = MealSuggestion.stepsFromJsonList(rawSteps);
 
      _selectedMeal = meal.copyWith(steps: steps);
      _selectedMealLogged = false;
      _state = DietFlowState.mealDetail;
    } catch (e) {
      _errorMessage = 'Could not generate instructions. Please try again.';
      _state = DietFlowState.error;
    }
 
    notifyListeners();
  }
 
  // ── Step 4: Finalize — write the selected meal's macros to the local DB ───
  Future<void> finalizeSelectedMeal() async {
    if (_selectedMeal == null || _selectedMealLogged) return;
 
    final meal = _selectedMeal!;
    await DietDatabaseService.instance.insertLog(
      DietLogEntry(
        date: DietDatabaseService.todayKey(),
        mealName: meal.name,
        tag: meal.tag,
        calories: meal.calories,
        protein: meal.macros.protein,
        carbs: meal.macros.carbs,
        fat: meal.macros.fat,
        loggedAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
 
    _selectedMealLogged = true;
    notifyListeners();
  }
 
  /// Log a saved meal directly — it already has macros, so no AI call needed.
  Future<void> finalizeSavedMeal(SavedMeal meal) async {
    await DietDatabaseService.instance.insertLog(
      DietLogEntry(
        date: DietDatabaseService.todayKey(),
        mealName: meal.name,
        tag: meal.tag,
        calories: meal.calories,
        protein: meal.protein,
        carbs: meal.carbs,
        fat: meal.fat,
        loggedAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
 
    _loggedSavedMealNames.add(meal.name);
    notifyListeners();
  }
 
  // ── Helpers ────────────────────────────────────────────────────────────────
  String _stripFences(String raw) {
    return raw
        .replaceAll(RegExp(r'^```json?\s*', multiLine: true), '')
        .replaceAll(RegExp(r'```$', multiLine: true), '')
        .trim();
  }
}