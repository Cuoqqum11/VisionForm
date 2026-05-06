import 'package:flutter/material.dart';
import '../Logic/diet_logic.dart';

class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  final DietLogic _logic = DietLogic();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diet'), backgroundColor: Colors.transparent),
      body: ListenableBuilder(
        listenable: _logic,
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SearchAnchor(
                  builder: (BuildContext context, SearchController controller) {
                    return SearchBar(
                      controller: controller,
                      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                        EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      hintText: 'Search food...',
                      leading: const Icon(Icons.search),
                      onTap: controller.openView,
                      onChanged: (_) => controller.openView(),
                    );
                  },
                  suggestionsBuilder:
                      (BuildContext context, SearchController controller) {
                    return _logic.filteredFoods(controller.text).map((food) {
                      return ListTile(
                        leading: const Icon(Icons.restaurant_menu),
                        title: Text(food.name),
                        subtitle: Text('${food.calories} kcal per 100g'),
                        onTap: () {
                          _logic.selectFood(food);
                          controller.closeView(food.name);
                          controller.text = food.name;
                        },
                      );
                    });
                  },
                ),
              ),

              // Nutrition card shown when a food is selected
              if (_logic.selectedFood != null)
                _NutritionCard(food: _logic.selectedFood!),

              // Image preview
              Expanded(
                child: Center(
                  child: _logic.image == null
                      ? const Text(
                          'No image selected',
                          style: TextStyle(color: Colors.white54),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            _logic.image!,
                            width: 300,
                            height: 500,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: _logic.pickImage,
        child: const Icon(Icons.camera_alt, color: Colors.black),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final FoodItem food;
  const _NutritionCard({required this.food});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 37, 39),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            food.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Per 100g',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NutrientBadge(label: 'Calories', value: '${food.calories}', unit: 'kcal', color: Colors.orange),
              _NutrientBadge(label: 'Protein',  value: '${food.protein}',  unit: 'g',    color: const Color(0xFF5B8CFF)),
              _NutrientBadge(label: 'Carbs',    value: '${food.carbs}',    unit: 'g',    color: const Color(0xFF4BC98A)),
              _NutrientBadge(label: 'Fat',      value: '${food.fat}',      unit: 'g',    color: const Color(0xFFFF6B6B)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutrientBadge extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _NutrientBadge({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 8, 14, 19),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                unit,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}