import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FoodItem {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const FoodItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class DietLogic extends ChangeNotifier {
  File? _image;
  FoodItem? _selectedFood;
  final ImagePicker _picker = ImagePicker();

  File? get image => _image;
  FoodItem? get selectedFood => _selectedFood;

  final List<FoodItem> foods = const [
    FoodItem(name: 'Chicken Breast', calories: 165, protein: 31,  carbs: 0,    fat: 3.6),
    FoodItem(name: 'Salmon',         calories: 208, protein: 20,  carbs: 0,    fat: 13),
    FoodItem(name: 'Rice',           calories: 130, protein: 2.7, carbs: 28,   fat: 0.3),
    FoodItem(name: 'Broccoli',       calories: 34,  protein: 2.8, carbs: 7,    fat: 0.4),
    FoodItem(name: 'Apple',          calories: 52,  protein: 0.3, carbs: 14,   fat: 0.2),
    FoodItem(name: 'Banana',         calories: 89,  protein: 1.1, carbs: 23,   fat: 0.3),
    FoodItem(name: 'Eggs',           calories: 155, protein: 13,  carbs: 1.1,  fat: 11),
    FoodItem(name: 'Avocado',        calories: 160, protein: 2,   carbs: 9,    fat: 15),
    FoodItem(name: 'Oatmeal',        calories: 68,  protein: 2.4, carbs: 12,   fat: 1.4),
    FoodItem(name: 'Yogurt',         calories: 59,  protein: 10,  carbs: 3.6,  fat: 0.4),
    FoodItem(name: 'Beef',           calories: 250, protein: 26,  carbs: 0,    fat: 15),
    FoodItem(name: 'Sweet Potato',   calories: 86,  protein: 1.6, carbs: 20,   fat: 0.1),
    FoodItem(name: 'Spinach',        calories: 23,  protein: 2.9, carbs: 3.6,  fat: 0.4),
    FoodItem(name: 'Carrot',         calories: 41,  protein: 0.9, carbs: 10,   fat: 0.2),
    FoodItem(name: 'Orange',         calories: 47,  protein: 0.9, carbs: 12,   fat: 0.1),
  ];

  List<FoodItem> filteredFoods(String query) {
    return foods
        .where((food) => food.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void selectFood(FoodItem food) {
    _selectedFood = food;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      notifyListeners();
    }
  }
}