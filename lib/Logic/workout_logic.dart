import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/workout_record_model.dart';
import '../models/workout_model.dart';
import '../database/database_service.dart';

class WorkoutProvide extends ChangeNotifier {
  List<Workout> _workout = [];
  List<WorkoutRecord> _workoutRecord = [];  
  Workout? _selectedWorkout;
  bool _isLoading = true;
  String? _errorMessage;

  List<Workout> get workout => _workout;
  List<WorkoutRecord> get workoutRecord => _workoutRecord;
  Workout? get selectedWorkout => _selectedWorkout;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initializeApp() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      int count = await DatabaseService.instance.getWorkoutCount();

      if (count == 0) {
        List<Workout> defaults = [
          Workout(
            name: 'Push-ups',
            description:
                'A basic upper body exercise that strengthens the chest, shoulders, and triceps.',
            imageUrl: 'assets/images/pushup.jpg',
            duration: 30,
            instruction: [
              'Setup',
              'Get down on the floor, face down',
              'Place your hands slightly wider than shoulder-width apart',
              'Keep your feet together (or slightly apart for balance)',
              'Straighten your arms fully',
              'Body Position',
              'Keep your body in a straight line (head -> shoulders -> hips -> heels)',
              'Engage your core (tighten your abs)',
              "Don't let your hips sag or stick up",
              'Lowering Phase',
              'Slowly bend your elbows',
              'Lower your chest toward the ground',
              'Keep elbows at about a 45-degree angle from your body (not flaring out too much)',
              'Bottom Position',
              'Stop when your chest is just above the floor',
              'Keep your body straight (no collapsing)',
              'Pushing Up',
              'Push through your palms',
              'Straighten your arms back to the starting position',
              'Exhale as you push up',
            ],
          ),
          Workout(
            name: 'pullups',
            description: 'Great for back and biceps.',
            imageUrl: 'assets/images/pullup.jpg',
            duration: 30,
            instruction: [
              'Setup',
              'Grab the pull-up bar with your palms facing away from you (overhand grip)',
              'Hands should be slightly wider than shoulder-width apart',
              'Hang with your arms fully extended and legs off the ground',
              'Engage your core and back muscles',
              'Pulling Up',
              'Pull yourself up by driving your elbows down toward your hips',
              'Keep your chest up and shoulders back',
              'Continue pulling until your chin is above the bar',
              'Lowering Down',
              'Slowly lower yourself back to the starting position with control',
              'Fully extend your arms at the bottom before starting the next rep',
            ],
          ),
          Workout(
            name: 'Squats',
            description:
                'A fundamental lower body exercise that targets the thighs, hips, and buttocks.',
            imageUrl: 'assets/images/squat.jpg',
            duration: 30,
            instruction: [
              'Setup',
              'Stand with your feet shoulder-width apart',
              'Toes should be slightly pointed out (about 15-30 degrees)',
              'Keep your chest up and shoulders back',
              'Engage your core muscles',
              'Squatting Down',
              'Initiate the movement by pushing your hips back as if sitting in a chair',
              'Bend your knees and lower your body down',
              'Keep your weight on your heels (not on your toes)',
              'Lower until your thighs are at least parallel to the ground (or as low as comfortable)',
              'Pushing Up',
              'Drive through your heels to return to the starting position',
              'Straighten your legs and squeeze your glutes at the top',
              'Exhale as you push up',
            ],
          ),
          Workout(
            name: 'Sit up',
            description: 'An abdominal exercise that strengthens the core muscles.',
            imageUrl: 'assets/images/situp.jpg',
            duration: 30,
            instruction: [
              'Setup',
              'Lie on your back with your knees bent and feet flat on the ground',
              'Place your hands behind your head or across your chest',
              'Engage your core muscles',
              'Lifting Phase',
              'Sit up by lifting your shoulders off the ground',
              'Keep your elbows close to your ears',
              'Lowering Phase',
              'Slowly lower yourself back to the starting position',
            ],
          ),
        ];
        for (var workout in defaults) {
          await DatabaseService.instance.insertWorkout(workout);
        }
      }

      await refreshWorkouts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWorkouts() async {
    _workout = await DatabaseService.instance.getWorkout();
    notifyListeners(); // Shouts to the UI to update!
  }

  void selectWorkout(Workout workout){
    _selectedWorkout = workout;
    fetchHistory(workout.id!);
    notifyListeners();
  }

  Future<void> fetchHistory(int workoutId) async {
    _workoutRecord = await DatabaseService.instance.getWorkoutRecords(workoutId);
    notifyListeners();
  }

  Future<void> saveRecord({required int workoutId, required int duration, required int reps, required int sets, required String notes}) async {
    WorkoutRecord record = WorkoutRecord(
      id: 0,
      workoutId: workoutId,
      date: DateTime.now(),
      timeStamp: DateTime.now().millisecondsSinceEpoch,
      duration: duration,
      reps: reps,
      sets: sets,
      notes: notes,
    );
    await DatabaseService.instance.insertWorkoutRecord(record);
    await fetchHistory(_selectedWorkout!.id!);
  }
}
