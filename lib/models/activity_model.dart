class ActivityModel {
  String id;
  String type; // 'step', 'exercise', 'food'
  double value;
  String unit;
  DateTime date;
  
  ActivityModel({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.date,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'unit': unit,
      'date': date.toIso8601String(),
    };
  }
  
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      value: json['value']?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      date: DateTime.parse(json['date']),
    );
  }
}