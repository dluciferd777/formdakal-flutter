// lib/providers/exercise_provider.dart - PERFORMANCE OPTIMIZED
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:formdakal/providers/user_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';
import '../services/calorie_service.dart';
import 'achievement_provider.dart';

class ExerciseProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  late AchievementProvider _achievementProvider;
  late UserProvider _userProvider;

  // Core Data
  List<CompletedExercise> _completedExercises = [];
  int _dailySteps = 0;
  int _dailyActiveMinutes = 0;

  // Step Counter Optimization
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  int _stepCount = 0;
  double _lastMagnitude = 0;
  bool _isStepDetected = false;
  int _savedStepsToday = 0;
  DateTime _lastStepTime = DateTime.now();
  Timer? _stepDebounceTimer;

  // Performance Optimization
  Timer? _saveTimer;
  bool _needsSaving = false;
  int _lastNotificationStep = 0;
  static const int _notificationThreshold = 10; // Her 10 adımda bir bildir
  static const int _saveInterval = 5000; // 5 saniyede bir kaydet

  // Gelişmiş adım algılama
  static const double _stepThreshold = 8.0;
  static const int _minTimeBetweenSteps = 200; // milliseconds
  static const int _smoothingWindowSize = 5;
  final List<double> _magnitudeHistory = [];

  // Caching
  String? _cachedTodayKey;
  DateTime? _lastCacheUpdate;

  // Keys
  static const _exercisesKey = 'completed_exercises';
  static const _stepsKey = 'daily_steps_';
  static const _minutesKey = 'daily_minutes_';

  ExerciseProvider(this._prefs, this._achievementProvider, this._userProvider) {
    _initProvider();
  }

  // Getters
  List<CompletedExercise> get completedExercises => List.unmodifiable(_completedExercises);
  int get dailySteps => _dailySteps;
  int get dailyActiveMinutes => _dailyActiveMinutes;

  /// Provider initialization - optimized startup
  Future<void> _initProvider() async {
    await loadData();
    _initStepCounter();
    _startPeriodicSave();
  }

  void updateDependencies(AchievementProvider achProvider, UserProvider usrProvider) {
    _achievementProvider = achProvider;
    _userProvider = usrProvider;
  }

  /// Optimized step counter with advanced algorithm
  void _initStepCounter() {
    _accelerometerSubscription = userAccelerometerEvents.listen(
      _detectStepAdvanced,
      onError: (error) {
        debugPrint("🚨 Accelerometer error: $error");
        _handleSensorError();
      },
      cancelOnError: false, // Don't cancel on error, retry
    );
  }

  /// Advanced step detection with smoothing and debouncing
  void _detectStepAdvanced(UserAccelerometerEvent event) {
    try {
      // Calculate vector magnitude with square root
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Magnitude smoothing
      _magnitudeHistory.add(magnitude);
      if (_magnitudeHistory.length > _smoothingWindowSize) {
        _magnitudeHistory.removeAt(0);
      }
      
      // Smoothed magnitude
      double smoothedMagnitude = _magnitudeHistory.reduce((a, b) => a + b) / _magnitudeHistory.length;
      
      // Time-based filtering
      DateTime now = DateTime.now();
      bool enoughTimePassed = now.difference(_lastStepTime).inMilliseconds > _minTimeBetweenSteps;
      
      // Step detection conditions
      if (_shouldDetectStep(smoothedMagnitude, magnitude, enoughTimePassed)) {
        _processNewStep(now);
      }
      
      _lastMagnitude = magnitude;
    } catch (e) {
      debugPrint("🚨 Step detection error: $e");
    }
  }

  /// Optimized step detection logic
  bool _shouldDetectStep(double smoothedMagnitude, double magnitude, bool enoughTimePassed) {
    return smoothedMagnitude > _stepThreshold && 
           enoughTimePassed && 
           magnitude > _lastMagnitude && 
           !_isStepDetected &&
           _magnitudeHistory.length >= 3;
  }

  /// Process new step with optimizations
  void _processNewStep(DateTime now) {
    _stepCount++;
    _isStepDetected = true;
    _lastStepTime = now;
    
    // Update step count
    _dailySteps = _savedStepsToday + _stepCount;
    _needsSaving = true;
    
    // Debounced notification - only notify UI every N steps
    if (_dailySteps - _lastNotificationStep >= _notificationThreshold) {
      _lastNotificationStep = _dailySteps;
      notifyListeners();
    }
    
    // Reset step detection flag
    _stepDebounceTimer?.cancel();
    _stepDebounceTimer = Timer(Duration(milliseconds: _minTimeBetweenSteps), () {
      _isStepDetected = false;
    });

    // Debug logging (remove in production)
    if (_stepCount % 100 == 0) {
      debugPrint("🦶 Steps: $_dailySteps (magnitude: ${_lastMagnitude.toStringAsFixed(2)})");
    }
  }

  /// Handle sensor errors gracefully
  void _handleSensorError() {
    _accelerometerSubscription?.cancel();
    
    // Retry after delay
    Timer(const Duration(seconds: 2), () {
      if (!_isDisposed) {
        _initStepCounter();
      }
    });
  }

  /// Periodic save system - reduces I/O operations
  void _startPeriodicSave() {
    _saveTimer = Timer.periodic(Duration(milliseconds: _saveInterval), (timer) {
      if (_needsSaving) {
        _saveStepsOptimized();
        _needsSaving = false;
      }
    });
  }

  /// Optimized data loading with caching
  Future<void> loadData() async {
    try {
      // Load exercises
      final exerciseJson = _prefs.getString(_exercisesKey);
      if (exerciseJson != null) {
        final List<dynamic> decoded = jsonDecode(exerciseJson);
        _completedExercises = decoded
            .map((item) => CompletedExercise.fromJson(item))
            .toList();
      }

      // Load today's data with caching
      final todayKey = _getTodayKey();
      _savedStepsToday = _prefs.getInt(_stepsKey + todayKey) ?? 0;
      _dailySteps = _savedStepsToday;
      _dailyActiveMinutes = _prefs.getInt(_minutesKey + todayKey) ?? 0;

      // Check if it's a new day - reset counters
      _checkNewDay();

      notifyListeners();
    } catch (e) {
      debugPrint("🚨 Data loading error: $e");
    }
  }

  /// Check if it's a new day and reset counters
  void _checkNewDay() {
    final currentDay = _getTodayKey();
    if (_cachedTodayKey != null && _cachedTodayKey != currentDay) {
      // New day detected - reset step counter
      _stepCount = 0;
      _savedStepsToday = 0;
      _dailySteps = 0;
      debugPrint("🌅 New day detected - resetting step counter");
    }
    _cachedTodayKey = currentDay;
    _lastCacheUpdate = DateTime.now();
  }

  /// Optimized step saving - reduces SharedPreferences calls
  Future<void> _saveStepsOptimized() async {
    try {
      final todayKey = _getTodayKey();
      await _prefs.setInt(_stepsKey + todayKey, _dailySteps);
    } catch (e) {
      debugPrint("🚨 Step saving error: $e");
    }
  }

  /// Get today key with caching
  String _getTodayKey() {
    final now = DateTime.now();
    
    // Cache for 1 minute to avoid repeated date calculations
    if (_cachedTodayKey != null && 
        _lastCacheUpdate != null && 
        now.difference(_lastCacheUpdate!).inMinutes < 1) {
      return _cachedTodayKey!;
    }
    
    _cachedTodayKey = now.toIso8601String().substring(0, 10);
    _lastCacheUpdate = now;
    return _cachedTodayKey!;
  }

  /// Optimized exercise operations
  Future<void> _saveCompletedExercises() async {
    try {
      final jsonList = _completedExercises.map((exercise) => exercise.toJson()).toList();
      await _prefs.setString(_exercisesKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint("🚨 Exercise saving error: $e");
    }
  }

  Future<void> addCompletedExercise(CompletedExercise exercise) async {
    _completedExercises.add(exercise);
    await _saveCompletedExercises();
    _checkWorkoutAchievements();
    notifyListeners();
  }

  Future<void> removeCompletedExercise(int index) async {
    if (index >= 0 && index < _completedExercises.length) {
      _completedExercises.removeAt(index);
      await _saveCompletedExercises();
      notifyListeners();
    }
  }

  Future<void> removeCompletedExerciseById(String id) async {
    final initialLength = _completedExercises.length;
    _completedExercises.removeWhere((exercise) => exercise.id == id);
    
    if (_completedExercises.length != initialLength) {
      await _saveCompletedExercises();
      notifyListeners();
    }
  }

  /// Achievement checking with optimization
  void _checkWorkoutAchievements() {
    try {
      if (_completedExercises.length == 1) {
        _achievementProvider.unlockAchievement('first_workout');
      }
      // Add more achievement checks here
    } catch (e) {
      debugPrint("🚨 Achievement check error: $e");
    }
  }

  /// Optimized calorie calculation with caching
  double getDailyBurnedCalories(DateTime date) {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Exercise calories
      double exerciseCalories = _completedExercises
          .where((exercise) =>
              exercise.completedAt.isAfter(startOfDay) &&
              exercise.completedAt.isBefore(endOfDay))
          .fold(0.0, (total, exercise) => total + exercise.burnedCalories);

      // Step calories (only for today)
      double stepCalories = 0.0;
      final todayKey = _getTodayKey();
      final dateKey = date.toIso8601String().substring(0, 10);
      
      if (dateKey == todayKey && _dailySteps > 0) {
        final userWeight = _userProvider.user?.weight ?? 70.0;
        if (userWeight > 0) {
          stepCalories = CalorieService.calculateStepCalories(_dailySteps, userWeight);
        }
      }
      
      return exerciseCalories + stepCalories;
    } catch (e) {
      debugPrint("🚨 Calorie calculation error: $e");
      return 0.0;
    }
  }

  /// Optimized exercise minutes calculation
  int getDailyExerciseMinutes(DateTime date) {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      return _completedExercises
          .where((exercise) =>
              exercise.completedAt.isAfter(startOfDay) &&
              exercise.completedAt.isBefore(endOfDay))
          .fold(0, (total, exercise) => total + exercise.durationMinutes);
    } catch (e) {
      debugPrint("🚨 Exercise minutes calculation error: $e");
      return 0;
    }
  }

  /// Manual step addition for testing
  void addManualSteps(int steps) {
    _dailySteps += steps;
    _needsSaving = true;
    notifyListeners();
    debugPrint("🧪 Manual steps added: $steps, Total: $_dailySteps");
  }

  /// Reset daily steps (for testing or new day)
  Future<void> resetDailySteps() async {
    _stepCount = 0;
    _savedStepsToday = 0;
    _dailySteps = 0;
    _needsSaving = true;
    await _saveStepsOptimized();
    notifyListeners();
    debugPrint("🔄 Daily steps reset");
  }

  /// Force save all data
  Future<void> forceSave() async {
    if (_needsSaving) {
      await _saveStepsOptimized();
      _needsSaving = false;
    }
    await _saveCompletedExercises();
    debugPrint("💾 Force save completed");
  }

  /// Get step statistics
  Map<String, dynamic> getStepStatistics() {
    return {
      'dailySteps': _dailySteps,
      'sessionSteps': _stepCount,
      'savedSteps': _savedStepsToday,
      'isDetecting': _accelerometerSubscription != null,
      'lastMagnitude': _lastMagnitude,
      'historySize': _magnitudeHistory.length,
    };
  }

  // Disposal tracking
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    
    // Cancel all timers and subscriptions
    _accelerometerSubscription?.cancel();
    _saveTimer?.cancel();
    _stepDebounceTimer?.cancel();
    
    // Force save before disposal
    if (_needsSaving) {
      _saveStepsOptimized();
    }
    
    debugPrint("🗑️ ExerciseProvider disposed");
    super.dispose();
  }
}