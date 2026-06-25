import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemini/flutter_gemini.dart'; // Kept Gemini package

import 'Logic/diet_logic.dart';
import "Logic/home_logic.dart";
import 'Logic/workout_logic.dart';
import 'UI/workoutUI.dart';
import 'UI/workout_detail_screen.dart';
import 'UI/diet_UI.dart';
import "UI/homeUI.dart";

Future<void> main() async {
  // Ensure Flutter bindings are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  
  // Directly passing the API key string to completely bypass flutter_dotenv
  const String apiKey = 'AQ.Ab8RN6J9IZm8lUwmQ9N9sef7NGCUVjhjznLgEk2YIQBwGzYoJg';

  Gemini.init(
    apiKey: apiKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WorkoutProvide()),
        ChangeNotifierProvider(create: (context) => DietLogic()),
      ],
      child: const MyApp(),
    ),    
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        primaryColor: Colors.orange,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkoutProvide>(context, listen: false).initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedWorkout = context.watch<WorkoutProvide>().selectedWorkout;
    
    // NOTE: If 'data' throws a compiler error, replace it with actual data from your provider 
    // e.g., Provider.of<HomeLogic>(context).yourData
    
    // NOTE: If 'data' throws a compiler error, replace it with actual data from your provider 
    // e.g., Provider.of<HomeLogic>(context).yourData
    final List<Widget> pages = [
      HomeUI(data: data), 
      selectedWorkout == null
          ? WorkoutListScreen(
              onWorkoutSelected: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
            )
          : const WorkoutDetailScreen(),
      const DietPage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF2D2F36),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Diet'),
        ],
      ),
    );
  }
}