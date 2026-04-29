import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diet Page')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: SearchAnchor(
              builder: (BuildContext context, SearchController controller) {
                return SearchBar(
                  controller: controller,
                  padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                    EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  leading: const Icon(Icons.search),
                  onTap: controller.openView,
                  onChanged: (_) => controller.openView(),
                );
              },
              suggestionsBuilder:
                  (BuildContext context, SearchController controller) {
                    final List<String> foods = [
                      'Chicken Breast',
                      'Salmon',
                      'Rice',
                      'Broccoli',
                      'Apple',
                      'Banana',
                      'Eggs',
                      'Avocado',
                      'Oatmeal',
                      'Yogurt',
                      'Beef',
                      'Sweet Potato',
                      'Spinach',
                      'Carrot',
                      'Orange',
                    ];

                    final query = controller.text.toLowerCase();

                    final filteredFoods = foods.where((food) {
                      return food.toLowerCase().contains(query);
                    }).toList();

                    return filteredFoods.map((food) {
                      return ListTile(
                        leading: const Icon(Icons.restaurant_menu),
                        title: Text(food),
                        onTap: () {
                          controller.closeView(food);
                          controller.text = food;
                        },
                      );
                    });
                  },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: _image == null
                  ? const Text('No image selected')
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _image!,
                        width: 300,
                        height: 500,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
