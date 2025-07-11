// lib/providers/progress_photo_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_photo_model.dart';

class ProgressPhotoProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  List<ProgressPhotoModel> _photos = [];
  static const _storageKey = 'progress_photos';

  ProgressPhotoProvider(this._prefs) {
    loadPhotos();
  }

  List<ProgressPhotoModel> get photos => _photos;

  // Kayıtlı fotoğrafları SharedPreferences'tan yükler
  Future<void> loadPhotos() async {
    final dataString = _prefs.getString(_storageKey);
    if (dataString != null) {
      final List<dynamic> jsonData = jsonDecode(dataString);
      _photos = jsonData.map((item) => ProgressPhotoModel.fromJson(item)).toList();
      // Fotoğrafları tarihe göre en yeniden en eskiye sırala
      _photos.sort((a, b) => b.date.compareTo(a.date));
    }
    notifyListeners();
  }

  // Fotoğraf listesini SharedPreferences'a kaydeder
  Future<void> _savePhotos() async {
    final List<Map<String, dynamic>> jsonData = _photos.map((item) => item.toJson()).toList();
    await _prefs.setString(_storageKey, jsonEncode(jsonData));
  }

  // Yeni bir fotoğraf ekler
  Future<void> addPhoto(ProgressPhotoModel photo) async {
    _photos.add(photo);
    _photos.sort((a, b) => b.date.compareTo(a.date)); // Sıralamayı koru
    await _savePhotos();
    notifyListeners();
  }

  // ID'ye göre bir fotoğrafı siler
  Future<void> deletePhoto(String id) async {
    _photos.removeWhere((item) => item.id == id);
    await _savePhotos();
    notifyListeners();
  }
}