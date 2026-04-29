  final List<HomeLogic> data = [
    HomeLogic(day: "Monday", repitition: 20, accuracy: 78),
    HomeLogic(day: "Tuesday", repitition: 25, accuracy: 76),
    HomeLogic(day: "Wednesday", repitition: 25, accuracy: 80),
    HomeLogic(day: "Thursday", repitition: 25, accuracy: 83),
    HomeLogic(day: "Friday", repitition: 30, accuracy: 85),
    HomeLogic(day: "Saturday", repitition: 31, accuracy: 77),
    HomeLogic(day: "Sunday", repitition: 35, accuracy: 88),
  ];

class HomeLogic {
  final String day;
  final int repitition;
  final double accuracy;
  bool isSelected;
  
  HomeLogic({
    required this.day,
    required this.repitition,
    required this.accuracy,
    this.isSelected = false,
  });

  // Calculate fill percentage based on accuracy (0-100%)
  double get fillPercentage => accuracy / 100;
}