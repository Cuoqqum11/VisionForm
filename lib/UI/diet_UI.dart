import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/diet_models.dart';
import 'package:flutter_application_1/Logic/diet_logic.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Shared colours — mirrors the rest of the app's dark theme
// ═════════════════════════════════════════════════════════════════════════════
class _C {
  static const bg = Color(0xFF080E13);
  static const surface = Color(0xFF1C1F24);
  static const card = Color(0xFF242527);
  static const cardHighlight = Color(0xFF2D2F36);
  static const gold = Color(0xFFD3A054);
  static const goldDim = Color(0x33D3A054);
  static const white = Colors.white;
  static const white70 = Colors.white70;
  static const white38 = Colors.white38;
}
 
// ═════════════════════════════════════════════════════════════════════════════
// Root widget — injects DietLogic and routes between states
// ═════════════════════════════════════════════════════════════════════════════
class DietPage extends StatelessWidget {
  const DietPage({super.key});
 
  @override
  Widget build(BuildContext context) {
    return const _DietRouter();
  }
}
 
class _DietRouter extends StatelessWidget {
  const _DietRouter();
 
  @override
  Widget build(BuildContext context) {
    final logic = context.watch<DietLogic>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: switch (logic.state) {
        DietFlowState.entry => const _EntryScreen(key: ValueKey('entry')),
        DietFlowState.review => const _ReviewScreen(key: ValueKey('review')),
        DietFlowState.loading => const _LoadingScreen(key: ValueKey('loading')),
        DietFlowState.mealList =>
          const _MealListScreen(key: ValueKey('mealList')),
        DietFlowState.mealDetail =>
          const _MealDetailScreen(key: ValueKey('mealDetail')),
        DietFlowState.error => _ErrorScreen(
            key: const ValueKey('error'),
            message: logic.errorMessage ?? 'Something went wrong.',
          ),
      },
    );
  }
}
 
// ═════════════════════════════════════════════════════════════════════════════
// STATE 1 — Entry screen
// ═════════════════════════════════════════════════════════════════════════════
class _EntryScreen extends StatelessWidget {
  const _EntryScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    final diet = context.watch<DietLogic>();
 
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        title: const Text(
          'Diet',
          style: TextStyle(color: _C.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
 
              // ── Profile pickers ────────────────────────────────────────
              _ProfilePickers(logic: diet),
              const SizedBox(height: 24),
 
              // ── Ingredient Input Box (Replaced Camera Scan) ───────────
              _IngredientInputSection(logic: diet),
              const SizedBox(height: 28),
 
              // ── Saved meals ────────────────────────────────────────────
              if (diet.savedMeals.isNotEmpty) ...[
                Row(
                  children: const [
                    Text(
                      'Saved meals',
                      style: TextStyle(
                          color: _C.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6),
                    ),
                    Spacer(),
                    Text(
                      'Tap to view',
                      style: TextStyle(color: _C.white38, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: diet.savedMeals.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final meal = diet.savedMeals[i];
                      return _SavedMealCard(
                        meal: meal,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ingredient input section (replaces camera scan) ───────────────────
class _IngredientInputSection extends StatefulWidget {
  final DietLogic logic;
  const _IngredientInputSection({required this.logic});

  @override
  State<_IngredientInputSection> createState() => _IngredientInputSectionState();
}

class _IngredientInputSectionState extends State<_IngredientInputSection> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final text = _ctrl.text.trim();
    if (text.isNotEmpty) {
      widget.logic.addIngredient(text);
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = widget.logic.allIngredients;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add your ingredients',
            style: TextStyle(color: _C.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: _C.white, fontSize: 14),
                  onSubmitted: (_) => _add(),
                  decoration: InputDecoration(
                    hintText: 'e.g. chicken, rice, broccoli...',
                    hintStyle: const TextStyle(color: _C.white38, fontSize: 14),
                    filled: true,
                    fillColor: _C.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: _C.white38, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: _C.gold, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: _C.white38, width: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _add,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _C.goldDim,
                    shape: BoxShape.circle,
                    border: Border.all(color: _C.gold, width: 1),
                  ),
                  child: const Icon(Icons.add, color: _C.gold, size: 22),
                ),
              ),
            ],
          ),
          if (ingredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ingredients.map((name) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _C.goldDim, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name, style: const TextStyle(color: _C.white70, fontSize: 12)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => widget.logic.removeIngredient(name),
                        child: const Icon(Icons.close, color: _C.white38, size: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: ingredients.isEmpty ? null : widget.logic.getMealRecommendations,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.gold,
                disabledBackgroundColor: _C.surface,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Find meals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('(${ingredients.length} ingredient${ingredients.length == 1 ? '' : 's'})', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
// ── Profile pickers (goal + diet type) ──────────────────────────────────
class _ProfilePickers extends StatelessWidget {
  final DietLogic logic;
  const _ProfilePickers({required this.logic});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your profile',
            style: TextStyle(
                color: _C.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LabeledDropdown(
                  icon: Icons.flag_outlined,
                  label: 'Goal',
                  value: logic.profile.goal,
                  options: kGoalOptions,
                  onChanged: logic.setGoal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledDropdown(
                  icon: Icons.restaurant_outlined,
                  label: 'Diet type',
                  value: logic.profile.dietType,
                  options: kDietOptions,
                  onChanged: logic.setDietType,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
 
// ── A single labeled dropdown ───────────────────────────────────────────
class _LabeledDropdown extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
 
  const _LabeledDropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: _C.gold),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: _C.white38, fontSize: 11, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.goldDim, width: 1),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: _C.surface,
            icon:
                const Icon(Icons.expand_more, color: _C.gold, size: 18),
            style: const TextStyle(
                color: _C.white, fontSize: 13, fontWeight: FontWeight.w500),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}
 
// ── A saved meal card ───────────────────────────────────────────────────
class _SavedMealCard extends StatelessWidget {
  final SavedMeal meal;

  const _SavedMealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    final diet = context.watch<DietLogic>();
    final isLogged = diet.isSavedMealLoggedToday(meal.name);
    final tagColor = kTagColors[meal.tag] ?? _C.gold;
    return GestureDetector(
      onTap: () {
        diet.viewSavedMeal(meal); 
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLogged ? _C.gold : _C.surface,
            width: isLogged ? 1.2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    meal.name,
                    style: const TextStyle(
                        color: _C.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLogged)
                  const Icon(Icons.check_circle, color: _C.gold, size: 14),
              ],
            ),
            const Spacer(),
            _TagChip(label: meal.tag, color: tagColor),
            const SizedBox(height: 4),
            Text(
              isLogged ? 'Logged today' : '${meal.calories} kcal',
              style: TextStyle(
                color: isLogged ? _C.gold : _C.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ═════════════════════════════════════════════════════════════════════════════
// STATE 2 — Ingredient review screen (checkboxes)
// (Kept in code for routing safety, but no longer triggered by UI)
// ═════════════════════════════════════════════════════════════════════════════
class _ReviewScreen extends StatefulWidget {
  const _ReviewScreen({super.key});
 
  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}
 
class _ReviewScreenState extends State<_ReviewScreen> {
  final TextEditingController _addCtrl = TextEditingController();
 
  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }
 
  void _submitAdd(DietLogic logic) {
    logic.addIngredient(_addCtrl.text);
    _addCtrl.clear();
  }
 
  @override
  Widget build(BuildContext context) {
    final logic = context.watch<DietLogic>();
    final confirmed = logic.confirmedIngredients.length;
    final all = logic.allIngredients.length;
 
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: _C.white70, size: 18),
                    onPressed: logic.goToEntry, 
                  ),
                  const Expanded(
                    child: Text(
                      'Confirm ingredients',
                      style: TextStyle(color: _C.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '$confirmed / $all checked',
                    style: const TextStyle(color: _C.white38, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Expanded(
              child: logic.allIngredients.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No ingredients added yet.\nGo back and add some below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _C.white38, fontSize: 14),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      itemCount: logic.allIngredients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final name = logic.allIngredients[i];
                        final checked = logic.isIngredientChecked(name);
                        return _IngredientRow(
                          name: name,
                          checked: checked,
                          onToggle: () => logic.toggleIngredient(name),
                          onRemove: () => logic.removeIngredient(name),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addCtrl,
                      style: const TextStyle(color: _C.white, fontSize: 14),
                      onSubmitted: (_) => _submitAdd(context.read<DietLogic>()),
                      decoration: InputDecoration(
                        hintText: 'Add a missing ingredient…',
                        hintStyle: const TextStyle(color: _C.white38, fontSize: 14),
                        filled: true,
                        fillColor: _C.card,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: _C.white38, width: 0.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: _C.gold, width: 1)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: _C.white38, width: 0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _submitAdd(context.read<DietLogic>()),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: _C.goldDim, shape: BoxShape.circle, border: Border.all(color: _C.gold, width: 1)),
                      child: const Icon(Icons.add, color: _C.gold, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: confirmed == 0 ? null : context.read<DietLogic>().getMealRecommendations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.gold, disabledBackgroundColor: _C.surface, foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Find meals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('($confirmed ingredient${confirmed == 1 ? '' : 's'})', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── A single ingredient checkbox row ────────────────────────────────────
class _IngredientRow extends StatelessWidget {
  final String name;
  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
 
  const _IngredientRow({
    required this.name,
    required this.checked,
    required this.onToggle,
    required this.onRemove,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: checked ? _C.goldDim : _C.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: checked ? _C.gold : _C.surface, width: 1),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: checked ? _C.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: checked ? _C.gold : _C.white38, width: 1.5),
                    ),
                    child: checked ? const Icon(Icons.check, size: 15, color: Colors.black) : null,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  name,
                  style: TextStyle(
                    color: checked ? _C.white : _C.white70,
                    fontSize: 14,
                    fontWeight: checked ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: _C.white38, size: 18),
            onPressed: onRemove,
            tooltip: 'Remove ingredient',
          ),
        ],
      ),
    );
  }
}
 
// ═════════════════════════════════════════════════════════════════════════════
// LOADING — spinner while AI works
// ═════════════════════════════════════════════════════════════════════════════
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _C.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _C.gold, strokeWidth: 2.5),
            SizedBox(height: 20),
            Text('Thinking up meals…', style: TextStyle(color: _C.white70, fontSize: 15, fontWeight: FontWeight.w500)),
            SizedBox(height: 6),
            Text('Matching your goal and ingredients', style: TextStyle(color: _C.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
 
// ═════════════════════════════════════════════════════════════════════════════
// STATE 3 — Meal list (3 suggestions, full macros, "Make this" button)
// ═════════════════════════════════════════════════════════════════════════════
class _MealListScreen extends StatelessWidget {
  const _MealListScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    final logic = context.watch<DietLogic>();
 
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: _C.white70, size: 18), onPressed: logic.goToEntry),
                  const Expanded(child: Text('Meal suggestions', style: TextStyle(color: _C.white, fontSize: 17, fontWeight: FontWeight.bold))),
                  TextButton(onPressed: logic.goToEntry, child: const Text('Scan again', style: TextStyle(color: _C.gold, fontSize: 13))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  _InfoPill(label: logic.profile.goal),
                  const SizedBox(width: 8),
                  _InfoPill(label: logic.profile.dietType),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: logic.meals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, i) => _MealOptionCard(
                  meal: logic.meals[i],
                  onMakeThis: () => logic.selectMeal(logic.meals[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── A small profile info pill ───────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final String label;
  const _InfoPill({required this.label});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _C.goldDim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.gold.withOpacity(0.4), width: 0.5),
      ),
      child: Text(label, style: const TextStyle(color: _C.gold, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
 
// ═════════════════════════════════════════════════════════════════════════════
// Meal option card — shown in the meal list (no steps yet)
// ═════════════════════════════════════════════════════════════════════════════
class _MealOptionCard extends StatelessWidget {
  final MealSuggestion meal;
  final VoidCallback onMakeThis;

  const _MealOptionCard({required this.meal, required this.onMakeThis});

  @override
  Widget build(BuildContext context) {
    final tagColor = kTagColors[meal.tag] ?? _C.gold;

    return Container(
      decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.surface, width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _C.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      _TagChip(label: meal.tag, color: tagColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2D2F36), height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _MacroTile(label: 'Calories', value: '${meal.calories}', unit: 'kcal', color: _C.gold),
                _VerticalDivider(),
                _MacroTile(label: 'Protein', value: '${meal.macros.protein}', unit: 'g', color: const Color(0xFFD4845A)),
                _VerticalDivider(),
                _MacroTile(label: 'Carbs', value: '${meal.macros.carbs}', unit: 'g', color: const Color(0xFF5A8EA0)),
                _VerticalDivider(),
                _MacroTile(label: 'Fat', value: '${meal.macros.fat}', unit: 'g', color: const Color(0xFF9E7A5A)),
              ],
            ),
          ),
          if (meal.usedIngredients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Wrap(
                spacing: 6, runSpacing: 4,
                children: meal.usedIngredients.map((ing) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(6)),
                      child: Text(ing, style: const TextStyle(color: _C.white70, fontSize: 11)),
                    )).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onMakeThis,
                icon: const Icon(Icons.restaurant_menu, color: _C.gold, size: 16),
                label: const Text('Make this meal', style: TextStyle(color: _C.gold, fontSize: 14, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: _C.gold, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
// ═════════════════════════════════════════════════════════════════════════════
// STATE 4 — Meal detail (one chosen meal, instructions + Log + Save)
// ═════════════════════════════════════════════════════════════════════════════
class _MealDetailScreen extends StatefulWidget {
  const _MealDetailScreen({super.key});

  @override
  State<_MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<_MealDetailScreen> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final logic = context.read<DietLogic>();
      final meal = logic.selectedMeal;
      if (meal != null) {
        setState(() {
          _saved = logic.savedMeals.any((s) => s.name == meal.name);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final logic = context.watch<DietLogic>();
    final meal = logic.selectedMeal;

    if (meal == null) {
      return const Scaffold(backgroundColor: _C.bg, body: SizedBox());
    }

    final tagColor = kTagColors[meal.tag] ?? _C.gold;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: _C.white70, size: 18), onPressed: logic.backToMealList),
                  Expanded(child: Text('Your meal', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _C.white, fontSize: 17, fontWeight: FontWeight.bold))),
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(_saved ? Icons.bookmark : Icons.bookmark_outline, key: ValueKey(_saved), color: _saved ? _C.gold : _C.white38, size: 22),
                    ),
                    onPressed: _saved ? null : () { logic.saveMeal(meal); setState(() => _saved = true); },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.surface, width: 1)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meal.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _C.white, fontSize: 19, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            _TagChip(label: meal.tag, color: tagColor),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0xFF2D2F36), height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            _MacroTile(label: 'Calories', value: '${meal.calories}', unit: 'kcal', color: _C.gold),
                            _VerticalDivider(),
                            _MacroTile(label: 'Protein', value: '${meal.macros.protein}', unit: 'g', color: const Color(0xFFD4845A)),
                            _VerticalDivider(),
                            _MacroTile(label: 'Carbs', value: '${meal.macros.carbs}', unit: 'g', color: const Color(0xFF5A8EA0)),
                            _VerticalDivider(),
                            _MacroTile(label: 'Fat', value: '${meal.macros.fat}', unit: 'g', color: const Color(0xFF9E7A5A)),
                          ],
                        ),
                      ),
                      if (meal.usedIngredients.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Wrap(
                            spacing: 6, runSpacing: 4,
                            children: meal.usedIngredients.map((ing) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(6)),
                                  child: Text(ing, style: const TextStyle(color: _C.white70, fontSize: 11)),
                                )).toList(),
                          ),
                        ),
                      const Divider(color: Color(0xFF2D2F36), height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 13, 16, 4),
                        child: Row(
                          children: const [
                            Icon(Icons.menu_book_outlined, color: _C.white70, size: 16),
                            SizedBox(width: 8),
                            Text('How to make it', style: TextStyle(color: _C.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: meal.steps.map((step) => _StepRow(step: step)).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: logic.selectedMealLogged ? null : logic.finalizeSelectedMeal,
                  icon: Icon(logic.selectedMealLogged ? Icons.check_circle : Icons.check_circle_outline, size: 18),
                  label: Text(logic.selectedMealLogged ? 'Logged for today' : 'Log this meal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.gold, disabledBackgroundColor: _C.cardHighlight, disabledForegroundColor: _C.gold, foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ── A single cooking step row ───────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final MealStep step;
  const _StepRow({required this.step});
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24, margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(color: _C.goldDim, shape: BoxShape.circle, border: Border.all(color: _C.gold, width: 0.8)),
            child: Center(child: Text('${step.stepNumber}', style: const TextStyle(color: _C.gold, fontSize: 11, fontWeight: FontWeight.bold))),
          ),
          Expanded(child: Text(step.instruction, style: const TextStyle(color: _C.white70, fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }
}
 
// ── Macro tile ──────────────────────────────────────────────────────────
class _MacroTile extends StatelessWidget {
  final String label; final String value; final String unit; final Color color;
  const _MacroTile({required this.label, required this.value, required this.unit, required this.color});
 
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
                TextSpan(text: unit, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _C.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
 
// ── Thin vertical divider between macro tiles ───────────────────────────
class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 0.5, height: 32, color: const Color(0xFF2D2F36));
  }
}
 
// ── Tag chip ────────────────────────────────────────────────────────────
class _TagChip extends StatelessWidget {
  final String label; final Color color;
  const _TagChip({required this.label, required this.color});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.4), width: 0.8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
 
// ═════════════════════════════════════════════════════════════════════════════
// Error screen
// ═════════════════════════════════════════════════════════════════════════════
class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({super.key, required this.message});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _C.white70, fontSize: 15)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: context.read<DietLogic>().goToEntry,
                style: ElevatedButton.styleFrom(backgroundColor: _C.gold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}