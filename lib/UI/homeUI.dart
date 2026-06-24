import 'package:flutter/material.dart';
import "package:flutter_application_1/Logic/home_logic.dart";
import 'package:flutter_application_1/UI/yearly_progress_chart.dart';
import 'package:flutter_application_1/Logic/diet_logic.dart';
import 'package:provider/provider.dart';


class HomeUI extends StatelessWidget {
  final List<HomeLogic> data;
  const HomeUI({super.key, required this.data});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 14, 19),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 8, 14, 19),
        title: const Text(
          "VisionForm",
          style: TextStyle(
            color: Color.fromARGB(255, 219, 209, 209),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: HomeScreen(data: data),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<HomeLogic> data;
  
  const HomeScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {

    final diet = context.watch<DietLogic>();

    return SingleChildScrollView( 
      child: Column(
        children: [
          const SizedBox(height: 16),

        // 1. THE NEW YEARLY PROGRESS CHART
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: YearlyProgressChart(), 
        ),

          // 2. THE NUTRITION MACROS
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 36, 37, 39),
              borderRadius: BorderRadius.circular(20),
            ),
            height: 143,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 8, 14, 19),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      width: 80,
                      height: 80,
                      child: Center(
                        child: Text("${diet.todaysCalories}", style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("kcal", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 8, 14, 19),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      width: 80,
                      height: 80,
                      child: Center(
                        child: Text("${diet.todaysProtein}g", style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Protein", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ), 
                Column(
                  children: [ 
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 8, 14, 19),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      width: 80,
                      height: 80,
                      child: Center(
                        child: Text("${diet.todaysCarbs}g", style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Carbs", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),    
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 8, 14, 19),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      width: 80,
                      height: 80,
                      child: Center(
                        child: Text("${diet.todaysFat}g", style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Fat", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),  
              ]
            ),
          ),
        ],
      ),
    );
  }
}
