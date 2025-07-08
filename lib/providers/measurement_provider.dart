// lib/providers/measurement_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/measurement_model.dart';

class MeasurementProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  List<MeasurementModel> _measurements = [];
  static const _storageKey = 'user_measurements';

  MeasurementProvider(this._prefs) {
    loadMeasurements();
  }

  List<MeasurementModel> get measurements => _measurements;

  // Kayıtlı ölçümleri SharedPreferences'tan yükler
  Future<void> loadMeasurements() async {
    final dataString = _prefs.getString(_storageKey);
    if (dataString != null) {
      final List<dynamic> jsonData = jsonDecode(dataString);
      _measurements = jsonData.map((item) => MeasurementModel.fromJson(item)).toList();
      // Ölçümleri tarihe göre en yeniden en eskiye sırala
      _measurements.sort((a, b) => b.date.compareTo(a.date));
    }
    notifyListeners();
  }

  // Ölçüm listesini SharedPreferences'a kaydeder
  Future<void> _saveMeasurements() async {
    final List<Map<String, dynamic>> jsonData = _measurements.map((item) => item.toJson()).toList();
    await _prefs.setString(_storageKey, jsonEncode(jsonData));
  }

  // Yeni bir ölçüm ekler
  Future<void> addMeasurement(MeasurementModel measurement) async {
    _measurements.add(measurement);
    _measurements.sort((a, b) => b.date.compareTo(a.date)); // Sıralamayı koru
    await _saveMeasurements();
    notifyListeners();
  }
  
  // Mevcut bir ölçümü günceller
  Future<void> updateMeasurement(MeasurementModel updatedMeasurement) async {
    final index = _measurements.indexWhere((m) => m.id == updatedMeasurement.id);
    if (index != -1) {
      _measurements[index] = updatedMeasurement;
      await _saveMeasurements();
      notifyListeners();
    }
  }

  // ID'ye göre bir ölçümü siler
  Future<void> deleteMeasurement(String id) async {
    _measurements.removeWhere((item) => item.id == id);
    await _saveMeasurements();
    notifyListeners();
  }
}