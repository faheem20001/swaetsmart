class UserFitnessModel {
  final double height; // in cm
  final double weight; // in kg
  final double bmi;
  final double bmr;
  final String gender;
  final int age;

  UserFitnessModel({
    required this.height,
    required this.weight,
    required this.bmi,
    required this.bmr,
    required this.gender,
    required this.age,
  });

  Map<String, dynamic> toMap() => {
    'height': height,
    'weight': weight,
    'bmi': bmi,
    'bmr': bmr,
    'gender': gender,
    'age': age,
  };

  factory UserFitnessModel.fromMap(Map<String, dynamic> map) {
    return UserFitnessModel(
      height: (map['height'] ?? 0).toDouble(),
      weight: (map['weight'] ?? 0).toDouble(),
      bmi: (map['bmi'] ?? 0).toDouble(),
      bmr: (map['bmr'] ?? 0).toDouble(),
      gender: map['gender'] ?? 'male',
      age: (map['age'] ?? 20).toInt(),
    );
  }
}
