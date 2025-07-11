import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static SharedPreferences get instance {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
    return _prefs!;
  }
  
  // String değerler
  static Future<bool> setString(String key, String value) async {
    return await instance.setString(key, value);
  }
  
  static String? getString(String key) {
    return instance.getString(key);
  }
  
  // Int değerler
  static Future<bool> setInt(String key, int value) async {
    return await instance.setInt(key, value);
  }
  
  static int? getInt(String key) {
    return instance.getInt(key);
  }
  
  // Bool değerler
  static Future<bool> setBool(String key, bool value) async {
    return await instance.setBool(key, value);
  }
  
  static bool? getBool(String key) {
    return instance.getBool(key);
  }
  
  // Double değerler
  static Future<bool> setDouble(String key, double value) async {
    return await instance.setDouble(key, value);
  }
  
  static double? getDouble(String key) {
    return instance.getDouble(key);
  }
  
  // List değerler
  static Future<bool> setStringList(String key, List<String> value) async {
    return await instance.setStringList(key, value);
  }
  
  static List<String>? getStringList(String key) {
    return instance.getStringList(key);
  }
  
  // JSON objeler
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return await setString(key, jsonEncode(value));
  }
  
  static Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }
  
  // Silme işlemleri
  static Future<bool> remove(String key) async {
    return await instance.remove(key);
  }
  
  static Future<bool> clear() async {
    return await instance.clear();
  }
  
  // Tüm anahtarları getir
  static Set<String> getKeys() {
    return instance.getKeys();
  }
}