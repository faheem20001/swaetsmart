class DailyProgressModel {
  final DateTime date;
  final double caloriesBurned;
  final double caloriesConsumed;
  final double bmi;
  final double calorieTarget;

  DailyProgressModel({
    required this.date,
    required this.caloriesBurned,
    required this.caloriesConsumed,
    required this.bmi,
    this.calorieTarget = 2000,
  });

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'caloriesBurned': caloriesBurned,
    'caloriesConsumed': caloriesConsumed,
    'bmi': bmi,
    'calorieTarget': calorieTarget,
  };

  factory DailyProgressModel.fromMap(Map<String, dynamic> map) {
    return DailyProgressModel(
      date: DateTime.parse(map['date']),
      caloriesBurned: (map['caloriesBurned'] ?? 0).toDouble(),
      caloriesConsumed: (map['caloriesConsumed'] ?? 0).toDouble(),
      bmi: (map['bmi'] ?? 0).toDouble(),
      calorieTarget: (map['calorieTarget'] ?? 2000).toDouble(),
    );
  }
}
