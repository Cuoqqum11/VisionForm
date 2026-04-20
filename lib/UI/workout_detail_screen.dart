import 'package:flutter/material.dart';

class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Detail')),
      body: const Center(
        child: Text('Workout detail placeholder'),
      ),
    );
  }
}
