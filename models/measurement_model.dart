// lib/models/measurement_model.dart
import 'package:uuid/uuid.dart';

class MeasurementModel {
  final String id;
  final DateTime date;
  
  // Vücut ölçüleri (opsiyonel)
  double? chest;  // Göğüs (cm)
  double? waist;  // Bel (cm)
  double? hips;   // Kalça (cm)
  double? leftArm;  // Sol Kol (cm)
  double? rightArm; // Sağ Kol (cm)
  double? leftThigh; // Sol Bacak (cm)
  double? rightThigh;// Sağ Bacak (cm)
  
  MeasurementModel({
    String? id,
    required this.date,
    this.chest,
    this.waist,
    this.hips,
    this.leftArm,
    this.rightArm,
    this.leftThigh,
    this.rightThigh,
  }) : id = id ?? const Uuid().v4(); // Eğer id verilmezse yeni bir UUID oluştur

  // JSON'dan MeasurementModel nesnesi oluşturmak için (Veri okuma)
  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    return MeasurementModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      chest: json['chest']?.toDouble(),
      waist: json['waist']?.toDouble(),
      hips: json['hips']?.toDouble(),
      leftArm: json['leftArm']?.toDouble(),
      rightArm: json['rightArm']?.toDouble(),
      leftThigh: json['leftThigh']?.toDouble(),
      rightThigh: json['rightThigh']?.toDouble(),
    );
  }

  // MeasurementModel nesnesini JSON'a dönüştürmek için (Veri kaydetme)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'leftArm': leftArm,
      'rightArm': rightArm,
      'leftThigh': leftThigh,
      'rightThigh': rightThigh,
    };
  }
}