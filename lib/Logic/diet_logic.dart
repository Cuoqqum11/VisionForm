import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import '../models/diet_models.dart';
import '../database/diet_database_service.dart';
 
class DietLogic extends ChangeNotifier {
  // ── Profile ──────────────────────────────────────────────────────────────
  final UserDietProfile profile = UserDietProfile();
 
  // ── Flow state ─────────────────────────────────────────────────────────
  DietFlowState _state = DietFlowState.entry;
  DietFlowState get state => _state;
 
  bool _isViewingSavedMeal = false;

  // Prevents duplicate Gemini calls if the user taps repeatedly
  bool _isBusy = false;


  // ── Today's Macros (For Home Screen) ───────────────────────────────────
  int _todaysCalories = 0;
  int _todaysProtein = 0;
  int _todaysCarbs = 0;
  int _todaysFat = 0;

  int get todaysCalories => _todaysCalories;
  int get todaysProtein => _todaysProtein;
  int get todaysCarbs => _todaysCarbs;
  int get todaysFat => _todaysFat;

  Future<void> clearTodaysLogs() async {
    final todaysLogs = await DietDatabaseService.instance.getTodaysLogs();
    for (var log in todaysLogs) {
      if (log.id != null) {
        await DietDatabaseService.instance.deleteLog(log.id!);
      }
    }
    _selectedMealLogged = false;
    await _syncTodaysData();
  }
  
  Future<void> initialize() async {
    await _syncTodaysData();
  }

  Future<void> _syncTodaysData() async {
    final todaysLogs = await DietDatabaseService.instance.getTodaysLogs();
    _loggedSavedMealNames.clear();
    for (var log in todaysLogs) {
      _loggedSavedMealNames.add(log.mealName);
    }

    final totals = await DietDatabaseService.instance.getTodaysTotals();
    _todaysCalories = totals['calories'] ?? 0;
    _todaysProtein = totals['protein'] ?? 0;
    _todaysCarbs = totals['carbs'] ?? 0;
    _todaysFat = totals['fat'] ?? 0;

    notifyListeners();
  }
  
  // ── Ingredient review ────────────────────────────────────────────────────
  XFile? _pickedImage;
  XFile? get pickedImage => _pickedImage;
 
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
      usedIngredients: ['rice', 'eggs', 'peas', 'carrots', 'soy sauce'],
      steps: [
        MealStep(stepNumber: 1, instruction: 'Heat a lightly oiled skillet or wok over medium-high heat.'),
        MealStep(stepNumber: 2, instruction: 'Scramble the eggs in the pan, then remove and set aside.'),
        MealStep(stepNumber: 3, instruction: 'Add veggies to the pan and sauté until tender.'),
        MealStep(stepNumber: 4, instruction: 'Stir in the cooked rice, eggs, and soy sauce. Toss well.')
      ]
    ),
    const SavedMeal(
      name: 'Chicken bowl',
      tag: 'Goal match',
      calories: 510,
      protein: 38,
      carbs: 44,
      fat: 16,
      usedIngredients: ['chicken breast', 'brown rice', 'broccoli', 'teriyaki sauce'],
      steps: [
        MealStep(stepNumber: 1, instruction: 'Cook the brown rice according to package instructions.'),
        MealStep(stepNumber: 2, instruction: 'Chop chicken into bite-sized pieces and cook in a skillet until golden brown.'),
        MealStep(stepNumber: 3, instruction: 'Steam the broccoli until bright green and tender-crisp.'),
        MealStep(stepNumber: 4, instruction: 'Assemble the bowl: rice on the bottom, topped with chicken and broccoli. Drizzle with sauce.')
      ]
    ),
  ];
  List<SavedMeal> get savedMeals => List.unmodifiable(_savedMeals);
 
  // Tracks which saved meals have already been logged today
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
          usedIngredients: meal.usedIngredients,
          steps: meal.steps
        ),
      );
      notifyListeners();
    }
  }

  void viewSavedMeal(SavedMeal saved) {
    _isViewingSavedMeal = true; // Set flag when entering from main menu    
    _selectedMeal = MealSuggestion(
      name: saved.name,
      tag: saved.tag,
      calories: saved.calories,
      macros: MacroInfo(protein: saved.protein, carbs: saved.carbs, fat: saved.fat),
      usedIngredients: saved.usedIngredients,
      steps: saved.steps,
    );
    _selectedMealLogged = isSavedMealLoggedToday(saved.name);
    _state = DietFlowState.mealDetail;
    notifyListeners();
  }
 
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
    _isViewingSavedMeal = false; // Reset flag
    notifyListeners();
  }
 
  /// Back from the meal-detail screen. 
  /// Determines if we go back to the generated list or the home entry screen.
  void backToMealList() {
    if (_meals.isEmpty || _isViewingSavedMeal) {
      _isViewingSavedMeal = false;
      goToEntry();
      return;
    }
    _state = DietFlowState.mealList;
    _selectedMeal = null;
    _selectedMealLogged = false;
    notifyListeners();
  }
 
  // ── Step 1: Pick image & detect ingredients ───────────────────────────────
  Future<void> scanFridge({bool fromCamera = true}) async {
    if (_isBusy) return;

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (file == null) return;

    _isBusy = true;
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
      debugPrint('📥 RAW scanFridge response: $raw');
      final cleaned = _stripFences(raw);

      final List<dynamic> list = jsonDecode(cleaned) as List<dynamic>;
      for (final item in list) {
        final name = item.toString().trim();
        if (name.isNotEmpty) _ingredients[name] = true;
      }

      _state = DietFlowState.review;
    } catch (e) {
      debugPrint('🚨 GEMINI CRASH REPORT (scanFridge): $e');
      if (_isRateLimitError(e)) {
        _errorMessage = 'Gemini is busy — wait 30 seconds then try again.';
        _state = DietFlowState.error;
      } else {
        // Non-rate-limit error: still drop to review so user can type ingredients manually
        _state = DietFlowState.review;
      }
    } finally {
      _isBusy = false;
    }

    notifyListeners();
  }
 
  // ── Step 2: Generate 3 meal options (names + macros, no steps yet) ────────
  Future<void> getMealRecommendations() async {
    if (confirmedIngredients.isEmpty || _isBusy) return;

    _isBusy = true;
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
      debugPrint('📥 RAW getMealRecommendations response: $raw');
      final cleaned = _stripFences(raw);
      debugPrint('🧹 CLEANED getMealRecommendations: $cleaned');

      final List<dynamic> list = jsonDecode(cleaned) as List<dynamic>;

      _meals = list
          .map((item) => MealSuggestion.fromJson(item as Map<String, dynamic>))
          .toList();

      _state = DietFlowState.mealList;
    } catch (e) {
      debugPrint('🚨 GEMINI CRASH REPORT (getMealRecommendations): $e');
      _errorMessage = _isRateLimitError(e)
          ? 'Gemini is busy — wait 30 seconds then try again.'
          : 'Meal generation failed: $e';
      _state = DietFlowState.error;
    } finally {
      _isBusy = false;
    }

    notifyListeners();
  }
 
  // ── Step 3: User picked one meal — generate matching instructions ─────────
  Future<void> selectMeal(MealSuggestion meal) async {
    if (_isBusy) return;

    _isBusy = true;
    _isViewingSavedMeal = false;
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
      debugPrint('📥 RAW selectMeal response: $raw');
      final cleaned = _stripFences(raw);
      debugPrint('🧹 CLEANED selectMeal: $cleaned');

      final List<dynamic> rawSteps = jsonDecode(cleaned) as List<dynamic>;
      final steps = MealSuggestion.stepsFromJsonList(rawSteps);

      _selectedMeal = meal.copyWith(steps: steps);
      _selectedMealLogged = false;
      _state = DietFlowState.mealDetail;
    } catch (e) {
      debugPrint('🚨 GEMINI CRASH REPORT (selectMeal): $e');
      _errorMessage = _isRateLimitError(e)
          ? 'Gemini is busy — wait 30 seconds then try again.'
          : 'Recipe generation failed: $e';
      _state = DietFlowState.error;
    } finally {
      _isBusy = false;
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
    await _syncTodaysData(); 
    notifyListeners();
  }
 
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
    await _syncTodaysData(); 
    notifyListeners();
  }
  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns true if the error is a transient Gemini rate-limit or overload.
  bool _isRateLimitError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('429') ||
        s.contains('503') ||
        s.contains('rate limit') ||
        s.contains('quota') ||
        s.contains('overloaded') ||
        s.contains('unavailable');
  }

  /// Strips markdown fences and extracts the first JSON array or object from
  /// a raw Gemini response string.  Handles these common Gemini quirks:
  ///   - ```json ... ``` fences
  ///   - Leading / trailing prose
  ///   - Array wrapped inside an object  e.g. {"meals": [...]}
  String _stripFences(String raw) {
    // 1. Remove markdown code fences
    String text = raw
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();

    // 2. Try to grab the outermost JSON array first
    final arrayStart = text.indexOf('[');
    final arrayEnd = text.lastIndexOf(']');
    if (arrayStart != -1 && arrayEnd > arrayStart) {
      return text.substring(arrayStart, arrayEnd + 1);
    }

    // 3. Fall back to the outermost JSON object (Gemini sometimes wraps arrays)
    final objStart = text.indexOf('{');
    final objEnd = text.lastIndexOf('}');
    if (objStart != -1 && objEnd > objStart) {
      return text.substring(objStart, objEnd + 1);
    }

    // 4. Nothing found — return trimmed text and let jsonDecode throw clearly
    return text;
  }
}