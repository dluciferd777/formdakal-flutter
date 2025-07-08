class AppConstants {
  // Uygulama sabitleri
  static const String appName = 'FormdaKal';
  static const String appVersion = '1.0.0';
  
  // Varsayılan değerler
  static const int defaultStepGoal = 6000;
  static const int defaultCalorieGoal = 2000;
  static const int defaultWaterGoal = 2000; // ml
  
  // Storage keys
  static const String userKey = 'user';
  static const String themeKey = 'isDarkMode';
  static const String stepsKey = 'steps_';
  static const String consumedFoodsKey = 'consumed_foods';
  static const String completedExercisesKey = 'completed_exercises';
  static const String searchHistoryKey = 'search_history';
  
  // Exercise categories
  static const List<String> exerciseCategories = [
    'chest',
    'back', 
    'shoulder',
    'arm',
    'leg',
    'cardio'
  ];
  
  // Meal types
  static const List<String> mealTypes = [
    'breakfast',
    'lunch',
    'dinner'
  ];
}