import 'package:flutter/material.dart';
 
/// The three UI states of the diet flow.
enum DietFlowState { entry, review, loading, result, error }
 
/// Available fitness goals shown in the combo picker.
const List<String> kGoalOptions = [
  'Muscle gain',
  'Weight loss',
  'Maintenance',
  'Endurance',
];
 
/// Available diet types shown in the combo picker.
const List<String> kDietOptions = [
  'High protein',
  'Low carb',
  'Balanced',
  'Vegetarian',
  'Keto',
];
 
/// The user's persistent diet profile.
/// For the MVP this lives in memory; swap with SharedPreferences later.
class UserDietProfile {
  String goal;
  String dietType;
  final List<String> favoriteFoods;
 
  UserDietProfile({
    this.goal = 'Muscle gain',
    this.dietType = 'High protein',
    this.favoriteFoods = const ['chicken', 'eggs', 'rice', 'broccoli'],
  });
}
 
/// One macro nutrient value set.
class MacroInfo {
  final int protein;
  final int carbs;
  final int fat;
  const MacroInfo({
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}
 
/// A single cooking step for the "How to make it" section.
class MealStep {
  final int stepNumber;
  final String instruction;
  const MealStep({required this.stepNumber, required this.instruction});
}
 
/// A meal suggestion returned by Gemini.
class MealSuggestion {
  final String name;
  final List<String> usedIngredients;
  final int calories;
  final MacroInfo macros;
  final String tag; // e.g. "High protein", "Goal match", "Low carb"
  final List<MealStep> steps;
 
  const MealSuggestion({
    required this.name,
    required this.usedIngredients,
    required this.calories,
    required this.macros,
    required this.tag,
    required this.steps,
  });
 
  /// Parse a single meal JSON object from Gemini's response.
  factory MealSuggestion.fromJson(Map<String, dynamic> json) {
    final macroJson = json['macros'] as Map<String, dynamic>? ?? {};
    final stepsRaw = json['steps'] as List<dynamic>? ?? [];
 
    return MealSuggestion(
      name: json['name'] as String? ?? 'Meal',
      usedIngredients: List<String>.from(json['usedIngredients'] ?? []),
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      macros: MacroInfo(
        protein: (macroJson['protein'] as num?)?.toInt() ?? 0,
        carbs: (macroJson['carbs'] as num?)?.toInt() ?? 0,
        fat: (macroJson['fat'] as num?)?.toInt() ?? 0,
      ),
      tag: json['tag'] as String? ?? 'Goal match',
      steps: stepsRaw
          .asMap()
          .entries
          .map((e) => MealStep(
                stepNumber: e.key + 1,
                instruction: e.value as String? ?? '',
              ))
          .toList(),
    );
  }
}
 
/// A saved meal shown in the bottom row on the entry screen.
class SavedMeal {
  final String name;
  final String tag;
  final int calories;
  const SavedMeal({
    required this.name,
    required this.tag,
    required this.calories,
  });
}
 
/// Maps a tag label to a display colour.
const Map<String, Color> kTagColors = {
  'High protein': Color(0xFFD4845A),
  'Low carb': Color(0xFF5A9E7A),
  'Goal match': Color(0xFFD3A054),
  'Quick & easy': Color(0xFF5A7EB5),
  'Vegetarian': Color(0xFF7AB55A),
  'Keto': Color(0xFF9E5A7A),
  'Balanced': Color(0xFF5A8EA0),
};