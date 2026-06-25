import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import '../models/diet_models.dart';
import '../database/diet_database_service.dart';
import 'groq_service.dart'; // ← NEW

class DietLogic extends ChangeNotifier {
  // ── Profile ──────────────────────────────────────────────────────────────
  final UserDietProfile profile = UserDietProfile();

  // ── Flow state ─────────────────────────────────────────────────────────
  DietFlowState _state = DietFlowState.entry;
  DietFlowState get state => _state;

  bool _isViewingSavedMeal = false;

  // Prevents duplicate API calls if the user taps repeatedly
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
        MealStep(stepNumber: 4, instruction: 'Stir in the cooked rice, eggs, and soy sauce. Toss well.'),
      ],
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
        MealStep(stepNumber: 4, instruction: 'Assemble the bowl: rice on the bottom, topped with chicken and broccoli. Drizzle with sauce.'),
      ],
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
          steps: meal.steps,
        ),
      );
      notifyListeners();
    }
  }

  void viewSavedMeal(SavedMeal saved) {
    _isViewingSavedMeal = true;
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
    _isViewingSavedMeal = false;
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
      // FALLBACK: Drop to review so the user can type ingredients manually.
      _state = DietFlowState.review;
      _errorMessage = null;
    } finally {
      _isBusy = false;
    }

    notifyListeners();
  }

  // ── Step 2: Generate 3 meal options — 3-layer waterfall ──────────────────
  //
  //  Layer 1 → Gemini (primary, vision-capable)
  //  Layer 2 → Groq / Llama 3 (fast free fallback)
  //  Layer 3 → Hardcoded JSON (bulletproof demo safety net)
  //
  Future<void> getMealRecommendations() async {
    if (confirmedIngredients.isEmpty || _isBusy) return;

    _isBusy = true;
    _state = DietFlowState.loading;
    _errorMessage = null;
    notifyListeners();

    // The shared prompt is identical for both AI layers.
    final prompt = _buildMealRecommendationPrompt();

    // try/finally guarantees _isBusy is ALWAYS reset, regardless of which
    // layer exits (return, throw, or fallthrough). This was the root bug —
    // early returns in Layer 1/2 were skipping the reset entirely.
    try {

      // ── Layer 1: Gemini ──────────────────────────────────────────────────
      try {
        debugPrint('🤖 [Layer 1] Trying Gemini for meal recommendations…');
        final response = await Gemini.instance.prompt(
          parts: [Part.text(prompt)],
        );
        final raw = response?.output?.trim() ?? '';
        if (raw.isEmpty) throw Exception('Gemini returned an empty response.');

        debugPrint('📥 RAW Gemini getMealRecommendations: $raw');
        _meals = _parseMealJson(_stripFences(raw));
        debugPrint('✅ [Layer 1] Gemini succeeded — ${_meals.length} meals.');

        _state = DietFlowState.mealList;
        _errorMessage = null;
        return; // finally still runs — _isBusy will be reset.
      } catch (geminiError) {
        debugPrint('⚠️ [Layer 1] Gemini failed: $geminiError');
      }

      // ── Layer 2: Groq ────────────────────────────────────────────────────
      try {
        debugPrint('🦙 [Layer 2] Trying Groq for meal recommendations…');
        final groqRaw = await GroqService.instance.complete(prompt);
        if (groqRaw == null || groqRaw.isEmpty) {
          throw Exception('Groq returned null or empty.');
        }

        debugPrint('📥 RAW Groq getMealRecommendations: $groqRaw');
        _meals = _parseMealJson(_stripFences(groqRaw));
        debugPrint('✅ [Layer 2] Groq succeeded — ${_meals.length} meals.');

        _state = DietFlowState.mealList;
        _errorMessage = null;
        return; // finally still runs — _isBusy will be reset.
      } catch (groqError) {
        debugPrint('⚠️ [Layer 2] Groq failed: $groqError');
      }

      // ── Layer 3: Hardcoded offline fallback ──────────────────────────────
      debugPrint('🛡️ [Layer 3] Both APIs failed. Loading offline fallback meals.');
      const String fallbackJson = '''
[
  {
    "name": "Grilled Chicken Quinoa Bowl",
    "usedIngredients": ["chicken breast (150g)", "quinoa (100g)", "broccoli (1 cup)", "olive oil (1 tbsp)"],
    "calories": 450,
    "macros": {"protein": 40, "carbs": 35, "fat": 15},
    "tag": "High protein"
  },
  {
    "name": "Salmon Avocado Salad",
    "usedIngredients": ["salmon fillet (150g)", "avocado (1/2)", "mixed greens (2 cups)", "lemon (1)"],
    "calories": 520,
    "macros": {"protein": 35, "carbs": 15, "fat": 35},
    "tag": "Low carb"
  },
  {
    "name": "Turkey Whole Wheat Wrap",
    "usedIngredients": ["turkey slices (100g)", "whole wheat tortilla (1)", "spinach (1 cup)", "hummus (2 tbsp)"],
    "calories": 380,
    "macros": {"protein": 30, "carbs": 40, "fat": 12},
    "tag": "Quick & easy"
  }
]
''';
      _meals = _parseMealJson(fallbackJson);
      _state = DietFlowState.mealList;
      _errorMessage = null;
      debugPrint('✅ [Layer 3] Offline fallback loaded successfully.');

    } catch (unexpectedError) {
      debugPrint('🚨 Unexpected error in getMealRecommendations: $unexpectedError');
      _errorMessage = 'Could not load meal suggestions. Please try again.';
      _state = DietFlowState.error;
    } finally {
      // This ALWAYS runs — whether we returned early from Layer 1, Layer 2,
      // fell through to Layer 3, or hit an unexpected error.
      _isBusy = false;
      notifyListeners();
    }
  }

  // ── Step 3: User picked one meal — generate matching instructions ─────────
  //
  //  Layer 1 → Gemini
  //  Layer 2 → Groq / Llama 3
  //  Layer 3 → Generic hardcoded steps
  //
  Future<void> selectMeal(MealSuggestion meal) async {
    if (_isBusy) return;

    _isBusy = true;
    _isViewingSavedMeal = false;
    _state = DietFlowState.loading;
    _errorMessage = null;
    notifyListeners();

    final prompt = _buildStepsPrompt(meal);

    // try/finally guarantees _isBusy is ALWAYS reset no matter which
    // layer exits — same fix as getMealRecommendations.
    try {

      // ── Layer 1: Gemini ──────────────────────────────────────────────────
      try {
        debugPrint('🤖 [Layer 1] Trying Gemini for cooking steps…');
        final response = await Gemini.instance.prompt(
          parts: [Part.text(prompt)],
          model: 'gemini-1.5-flash',
        );
        final raw = response?.output?.trim() ?? '';
        if (raw.isEmpty) throw Exception('Gemini returned an empty response.');

        debugPrint('📥 RAW Gemini selectMeal: $raw');
        final steps = MealSuggestion.stepsFromJsonList(
          jsonDecode(_stripFences(raw)) as List<dynamic>,
        );
        _selectedMeal = meal.copyWith(steps: steps);
        _selectedMealLogged = false;
        _state = DietFlowState.mealDetail;
        _errorMessage = null;
        debugPrint('✅ [Layer 1] Gemini succeeded — ${steps.length} steps.');
        return; // finally still runs — _isBusy will be reset.
      } catch (geminiError) {
        debugPrint('⚠️ [Layer 1] Gemini failed: $geminiError');
      }

      // ── Layer 2: Groq ────────────────────────────────────────────────────
      try {
        debugPrint('🦙 [Layer 2] Trying Groq for cooking steps…');
        final groqRaw = await GroqService.instance.complete(prompt);
        if (groqRaw == null || groqRaw.isEmpty) {
          throw Exception('Groq returned null or empty.');
        }

        debugPrint('📥 RAW Groq selectMeal: $groqRaw');
        final steps = MealSuggestion.stepsFromJsonList(
          jsonDecode(_stripFences(groqRaw)) as List<dynamic>,
        );
        _selectedMeal = meal.copyWith(steps: steps);
        _selectedMealLogged = false;
        _state = DietFlowState.mealDetail;
        _errorMessage = null;
        debugPrint('✅ [Layer 2] Groq succeeded — ${steps.length} steps.');
        return; // finally still runs — _isBusy will be reset.
      } catch (groqError) {
        debugPrint('⚠️ [Layer 2] Groq failed: $groqError');
      }

      // ── Layer 3: Hardcoded generic cooking steps ─────────────────────────
      debugPrint('🛡️ [Layer 3] Both APIs failed. Loading generic cooking steps.');
      final List<dynamic> fallbackSteps = [
        'Preheat your oven or prepare your cooking station and gather all your ingredients.',
        'Prep the ingredients by washing, chopping, or measuring them as needed for the recipe.',
        'Cook the main components over medium heat, seasoning with salt, pepper, and your favourite spices.',
        'Combine everything together, ensuring it\'s heated through and beautifully plated.',
        'Let it rest for a couple of minutes before serving to lock in the flavours. Enjoy your meal!',
      ];
      _selectedMeal = meal.copyWith(
        steps: MealSuggestion.stepsFromJsonList(fallbackSteps),
      );
      _selectedMealLogged = false;
      _state = DietFlowState.mealDetail;
      _errorMessage = null;

    } catch (unexpectedError) {
      debugPrint('🚨 Unexpected error in selectMeal: $unexpectedError');
      _errorMessage = 'Could not load cooking steps. Please try again.';
      _state = DietFlowState.error;
    } finally {
      // Always runs — whether Layer 1, 2, 3, or an unexpected error.
      _isBusy = false;
      notifyListeners();
    }
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

  // ── Private prompt builders ────────────────────────────────────────────────

  String _buildMealRecommendationPrompt() => '''
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

  String _buildStepsPrompt(MealSuggestion meal) => '''
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

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Parses a JSON string into a list of [MealSuggestion] objects.
  /// Throws on malformed input so the waterfall catch block fires correctly.
  List<MealSuggestion> _parseMealJson(String json) {
    final List<dynamic> list = jsonDecode(json) as List<dynamic>;
    return list
        .map((item) => MealSuggestion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Returns true if the error is a transient rate-limit or overload signal.
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
  /// a raw AI response string.  Handles these common quirks:
  ///   - ```json ... ``` fences
  ///   - Leading / trailing prose
  ///   - Array wrapped inside an object e.g. {"meals": [...]}
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

    // 3. Fall back to the outermost JSON object (AI sometimes wraps arrays)
    final objStart = text.indexOf('{');
    final objEnd = text.lastIndexOf('}');
    if (objStart != -1 && objEnd > objStart) {
      return text.substring(objStart, objEnd + 1);
    }

    // 4. Nothing found — return trimmed text and let jsonDecode throw clearly
    return text;
  }
}