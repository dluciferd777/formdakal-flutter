// lib/models/weight_history_model.dart

class WeightHistoryModel {
  final double weight;
  final DateTime date;

  WeightHistoryModel({
    required this.weight,
    required this.date,
  });

  // JSON'dan WeightHistoryModel nesnesi oluşturma
  factory WeightHistoryModel.fromJson(Map<String, dynamic> json) {
    return WeightHistoryModel(
      weight: json['weight']?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date']),
    );
  }

  // WeightHistoryModel nesnesini JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'date': date.toIso8601String(),
    };
  }
}