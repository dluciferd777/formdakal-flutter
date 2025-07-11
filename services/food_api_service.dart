import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_model.dart'; // FoodModel'i import ediyoruz

class FoodApiService {
  // Edamam App ID ve App Key'leriniz
  static const String _appId = 'd3669583'; // Sizin Application ID'niz
  static const String _appKey = 'f896bdeba233cc209f9569c1637ed334'; // Sizin Application Key'iniz
  static const String _baseUrl = 'https://api.edamam.com/api/food-database/v2/parser'; // Edamam'ın Food Database API'si

  Future<List<FoodModel>> searchFoods(String query) async {
    if (query.isEmpty) {
      return [];
    }

    // Edamam API için arama sorgusu ve kimlik bilgileri
    final uri = Uri.parse('$_baseUrl?ingr=$query&app_id=$_appId&app_key=$_appKey');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        List<FoodModel> foods = [];

        if (data['hints'] != null) {
          for (var item in data['hints']) {
            final foodData = item['food'];
            if (foodData != null) {
              // Edamam yanıtı için FoodModel'in kendi fromJson metodunu kullanıyoruz
              final parsedFood = FoodModel.fromJsonEdamam(foodData); // Yeni metod adı
              foods.add(parsedFood);
            }
          }
        }
        return foods;
      } else {
        print('API Hatası: ${response.statusCode} - ${response.body}');
        throw Exception('Yiyecekler getirilemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('İstek sırasında hata oluştu: $e');
      throw Exception('Yiyecek arama başarısız oldu: $e');
    }
  }
}