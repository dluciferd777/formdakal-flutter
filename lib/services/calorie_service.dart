// lib/services/calorie_service.dart
import 'dart:math';

class CalorieService {
  
  static double calculateBMR({
    required String gender,
    required double weight,
    required double height,
    required int age,
    double? bodyFatPercentage,
  }) {
    if (bodyFatPercentage != null && bodyFatPercentage > 0) {
      double leanBodyMass = weight * (1 - (bodyFatPercentage / 100));
      return 370 + (21.6 * leanBodyMass);
    } else {
      if (gender == 'male') {
        return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
      } else {
        return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
      }
    }
  }
  
  static const Map<String, double> activityFactors = {
    'sedentary': 1.2, 'lightly_active': 1.375, 'moderately_active': 1.55,
    'very_active': 1.725, 'extremely_active': 1.9,
  };

  static double calculateTDEE({
    required String gender,
    required double weight,
    required double height,
    required int age,
    required String activityLevel,
    double? bodyFatPercentage,
  }) {
    final bmr = calculateBMR(
        gender: gender, weight: weight, height: height, age: age, bodyFatPercentage: bodyFatPercentage);
    return bmr * (activityFactors[activityLevel] ?? 1.55);
  }

  static double calculateDailyCalorieNeeds({
    required String gender,
    required double weight,
    required double height,
    required int age,
    required String activityLevel,
    required String goal,
    double? bodyFatPercentage,
  }) {
    final tdee = calculateTDEE(
        gender: gender, weight: weight, height: height, age: age, 
        activityLevel: activityLevel, bodyFatPercentage: bodyFatPercentage);
    switch (goal) {
      case 'lose_weight': return tdee - 500;
      case 'gain_muscle': return tdee + 300;
      case 'lose_weight_gain_muscle': return tdee - 200;
      case 'maintain':
      default: return tdee;
    }
  }

  // Treadmill MET değerini hesaplar. Hıza göre yürüme veya koşma formülü kullanılır.
  // Bu formüller, ACSM (American College of Sports Medicine) kılavuzlarından türetilmiştir.
  static double _calculateTreadmillMET(double speedKmh, double inclinePercent) {
    final speedMetersPerMin = speedKmh * 1000 / 60; // km/saat'i metre/dakika'ya çevir
    final grade = inclinePercent / 100; // Yüzde eğimi ondalık değere çevir
    double vo2; // ml/kg/dk cinsinden oksijen tüketimi

    // Hıza göre yürüme veya koşma formülünü seç
    // Genellikle 6.5 km/saat (yaklaşık 4 mil/saat) ve üzeri koşu olarak kabul edilir.
    if (speedKmh >= 6.5) { // Koşma formülü (ACSM)
      // VO2 = (0.2 * hız) + (0.9 * hız * eğim) + 3.5 (dinlenme MET'i)
      vo2 = (0.2 * speedMetersPerMin) + (0.9 * speedMetersPerMin * grade) + 3.5;
    } else { // Yürüme formülü (ACSM)
      // VO2 = (0.1 * hız) + (1.8 * hız * eğim) + 3.5 (dinlenme MET'i)
      vo2 = (0.1 * speedMetersPerMin) + (1.8 * speedMetersPerMin * grade) + 3.5;
    }
    
    final metValue = vo2 / 3.5; // VO2'yi MET'e çevir (1 MET = 3.5 ml/kg/dk)
    return metValue;
  }

  static double calculateCardioCalories({
    required String exerciseType,
    required double userWeight,
    required int durationMinutes,
    double? speed,
    double? incline,
    // double? metValueOverride, // KALDIRILDI: İsteğe bağlı MET değeri geçersiz kılma
  }) {
    double metValue;
    // if (metValueOverride != null && metValueOverride > 0) { // KALDIRILDI: Eğer bir MET değeri geçersiz kılma sağlanmışsa, onu kullan
    //   metValue = metValueOverride;
    // } else
    if (exerciseType.contains('treadmill') && speed != null) {
      // Treadmill için özel MET hesaplaması (eğer geçersiz kılma yoksa)
      metValue = _calculateTreadmillMET(speed, incline ?? 0.0);
    } else {
      // Diğer kardiyo türleri için sabit MET değerleri (yaklaşık değerler)
      switch (exerciseType) {
        case 'cycling': metValue = 7.0; break;
        case 'elliptical': metValue = 8.0; break;
        case 'rowing': metValue = 9.0; break;
        case 'swimming': metValue = 6.0; break;
        case 'jumping_jack': metValue = 5.0; break;
        case 'burpees': metValue = 8.0; break;
        case 'jump_rope': metValue = 8.0; break;
        case 'stair_climber': metValue = 9.0; break; 
        case 'boxing_training': metValue = 7.0; break; 
        default: metValue = 5.0; // Varsayılan MET değeri
      }
    }
    double hours = durationMinutes / 60.0; // Süreyi saate çevir
    // Kalori = MET * Vücut Ağırlığı (kg) * Süre (saat)
    return metValue * userWeight * hours;
  }

  static double calculateEnhancedExerciseCalories({ required double metValue, required double userWeight, required int sets, required int reps, required double? weightKg, int restBetweenSets = 60 }) {
    // Kuvvet antrenmanları için daha detaylı kalori hesaplaması
    // Tahmini antrenman süresi: (set * tekrar * her tekrar süresi) + (setler arası dinlenme)
    // Her tekrarın ortalama 2.5 saniye sürdüğü varsayıldı.
    double totalSeconds = (sets * reps * 2.5) + (max(0, sets - 1) * restBetweenSets);
    double hours = totalSeconds / 3600; // Saniyeyi saate çevir
    // Kalori = MET * Vücut Ağırlığı (kg) * Süre (saat)
    return metValue * userWeight * hours;
  }

  static double calculateStepCalories(int steps, double weightKg) {
    // Adım başına kalori yakımını hesaplar (yaklaşık değer)
    // Ortalama bir adımın 0.75 metre olduğu ve 1 kg ağırlık için 1 km'de 1 kalori yakıldığı varsayımıyla.
    // Formül: Adım Sayısı * (0.75 m / adım) * (1 kalori / kg / km) * (1 km / 1000 m) * (Vücut Ağırlığı / Referans Ağırlık)
    // Basitleştirilmiş katsayı: 0.045 = (0.75 * 1 / 1000) * (70kg referans)
    return steps * 0.045 * (weightKg / 70.0); // 70 kg referans alındı
  }

  static double calculateBMI(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0;
    double heightM = heightCm / 100; // Boyu metreye çevir
    return weightKg / (heightM * heightM); // BMI formülü: kilo (kg) / (boy (m) * boy (m))
  }
  
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Fazla Kilolu';
    return 'Obez';
  }
  
  static Map<String, double> getIdealWeightRange(double heightCm) {
    double heightM = heightCm / 100; // Boyu metreye çevir
    // İdeal kilo aralığı BMI 18.5 - 24.9 aralığına göre hesaplanır.
    return {'min': 18.5 * pow(heightM, 2), 'max': 24.9 * pow(heightM, 2)};
  }
  
  static int estimateExerciseDuration(int sets, int reps) {
    // Basit bir yaklaşımla egzersiz süresi tahmini (dakika)
    // Her tekrarın 2.5 saniye sürdüğü ve her set arasında 30 saniye dinlenme olduğu varsayıldı.
    double totalSeconds = (sets * reps * 2.5) + (max(0, sets - 1) * 30);
    return (totalSeconds / 60).ceil(); // Saniyeyi dakikaya çevir ve yukarı yuvarla
  }
  
  static double calculateDailyProteinNeeds({ required double weight, required String activityLevel, required String goal,}) {
    double proteinPerKg; // Kilo başına protein ihtiyacı (gram)
    if (goal == 'gain_muscle' || goal == 'lose_weight_gain_muscle' || activityLevel == 'very_active' || activityLevel == 'extremely_active') {
      proteinPerKg = 1.8; // Kas yapımı veya yüksek aktivite için daha yüksek protein
    } else if (goal == 'lose_weight') {
      proteinPerKg = 1.4; // Kilo kaybı için orta protein
    } else {
      proteinPerKg = 1.0; // Bakım için temel protein
    }
    return weight * proteinPerKg;
  }

  static double calculateDailyFatNeeds({required double dailyCalorieNeeds}) {
    // Günlük kalorinin %25'i yağdan gelsin (yaklaşık değer)
    return (dailyCalorieNeeds * 0.25) / 9; // 1g yağ = 9 kalori
  }

  static double calculateDailyCarbNeeds({required double dailyCalorieNeeds, required double proteinGrams, required double fatGrams}) {
    // Kalan kaloriler karbonhidrattan gelsin
    double caloriesFromProtein = proteinGrams * 4; // 1g protein = 4 kalori
    double caloriesFromFat = fatGrams * 9;     // 1g yağ = 9 kalori
    double remainingCalories = dailyCalorieNeeds - caloriesFromProtein - caloriesFromFat;
    return remainingCalories / 4; // 1g karbonhidrat = 4 kalori
  }

  static double calculateDailyWaterNeeds({ required double weight, required String activityLevel, }) {
    // Kilo başına 33ml su temel alınır.
    double baseWater = weight * 0.033; // Litre cinsinden
    // Aktivite seviyesine göre ek su ihtiyacı eklenir.
    if (activityLevel == 'very_active' || activityLevel == 'extremely_active') { 
      return baseWater + 1.0; // Litre (ekstra 1 litre)
    } else if (activityLevel == 'moderately_active') { 
      return baseWater + 0.5; // Litre (ekstra 0.5 litre)
    }
    return baseWater; // Litre
  }
}
