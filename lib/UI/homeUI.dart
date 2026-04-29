import 'package:flutter/material.dart';
import "package:flutter_application_1/Logic/home_logic.dart";

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
          "Random App Name",
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

class HomeScreen extends StatefulWidget {
  final List<HomeLogic> data;
  const HomeScreen({super.key, required this.data});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

    void toggleSelection(int index) {
    setState(() {
      widget.data[index].isSelected = !widget.data[index].isSelected;  // Modify data
    });
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 36, 37, 39),
            borderRadius: BorderRadius.circular(20),
          ),
          height: 250,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.data.length, (index) {
              return GestureDetector(
                onTap: () => toggleSelection(index), 
                child: _buildBar(widget.data[index]),
              );
            })
          )
        ),
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 36, 37, 39),
            borderRadius: BorderRadius.circular(20),
          ),
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 8, 14, 19),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color.fromARGB(255, 211, 160, 84), width: 2),
                ),
                width: 80,
                height: 80,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 8, 14, 19),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color.fromARGB(255, 211, 160, 84), width: 2),
                ),
                width: 80,
                height: 80,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 8, 14, 19),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color.fromARGB(255, 211, 160, 84), width: 2),
                ),
                width: 80,
                height: 80,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 8, 14, 19),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color.fromARGB(255, 211, 160, 84), width: 2),
                ),
                width: 80,
                height: 80,
              ),
            ],
          ),
        ),
      ],
    );
  }  
}

Widget _buildBar(HomeLogic data) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Opacity(
         opacity: data.isSelected ? 1.0 : 0.0,
         child: Container(
           margin: const EdgeInsets.only(bottom: 10),
           padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
           decoration: BoxDecoration(
             color: const Color.fromARGB(179, 201, 143, 95),
             borderRadius: BorderRadius.circular(12),
           ),
           child: Column(
             children: [
               Text(
                 'Rep: ${data.repitition.toInt()}',
                 style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
               ),
               Text(
                 'Acc: ${data.accuracy.toInt()}%',
                 style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
               ),
             ],
           ),
         ),
       ),
       Container(
        width: 8,
        height: 120,
        decoration: BoxDecoration(
          color: const Color.fromARGB(179, 26, 22, 17),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: data.fillPercentage.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(179, 211, 160, 84),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        data.day,
        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ],
  );
}   