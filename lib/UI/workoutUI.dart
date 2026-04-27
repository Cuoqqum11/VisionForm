import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Logic/workout_logic.dart';

class WorkoutListScreen extends StatelessWidget {
  final VoidCallback onWorkoutSelected;

  const WorkoutListScreen({super.key, required this.onWorkoutSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose your workout"), backgroundColor: Colors.transparent),
      body: Consumer<WorkoutProvide>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  provider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          if (provider.workout.isEmpty) {
            return const Center(
              child: Text(
                'No workouts found.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.workout.length,
            itemBuilder: (context, index) {
              final workout = provider.workout[index];
              return Card(
                color: const Color(0xFF2D2F36),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      workout.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image_not_supported, color: Colors.orange),
                        );
                      },
                    ),
                  ),
                  title: Text(workout.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(workout.description, style: const TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.orange),
                  onTap: () {
                    provider.selectWorkout(workout);
                    onWorkoutSelected(); // Tell Main to switch to the Detail tab
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}