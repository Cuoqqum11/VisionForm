  final List<HomeLogic> data = [
    HomeLogic(day: "Mon", repitition: 20, accuracy: 78),
    HomeLogic(day: "Tue", repitition: 25, accuracy: 76),
    HomeLogic(day: "Wed", repitition: 25, accuracy: 80),
    HomeLogic(day: "Thu", repitition: 25, accuracy: 83),
    HomeLogic(day: "Fri", repitition: 30, accuracy: 85),
    HomeLogic(day: "Sat", repitition: 31, accuracy: 77),
    HomeLogic(day: "Sun", repitition: 35, accuracy: 88),
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