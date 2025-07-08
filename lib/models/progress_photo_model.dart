// lib/models/progress_photo_model.dart
import 'package:uuid/uuid.dart';

class ProgressPhotoModel {
  final String id;
  final String imagePath; // Resmin telefondaki dosya yolu
  final DateTime date;    // Yüklendiği tarih

  ProgressPhotoModel({
    String? id,
    required this.imagePath,
    required this.date,
  }) : id = id ?? const Uuid().v4();

  // JSON'dan ProgressPhotoModel nesnesi oluşturma
  factory ProgressPhotoModel.fromJson(Map<String, dynamic> json) {
    return ProgressPhotoModel(
      id: json['id'],
      imagePath: json['imagePath'],
      date: DateTime.parse(json['date']),
    );
  }

  // ProgressPhotoModel nesnesini JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'date': date.toIso8601String(),
    };
  }
}