// lib/services/permission_service.dart - SADECE TEK SEFERLİK İZİN DÜZELTMESİ
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PermissionType {
  notification,
  sensors,
  storage,
  camera,
  location,
  scheduleExactAlarm,
}

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final Map<PermissionType, PermissionStatus> _permissionCache = {};
  bool _isInitialized = false;
  SharedPreferences? _prefs;

  // Tek seferlik izin kontrolü için
  static const String _sensorPermissionAsked = 'sensor_permission_asked';

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _checkAllPermissions();
      _isInitialized = true;
      debugPrint('✅ Permission service initialized');
    } catch (e) {
      debugPrint('❌ Permission service init error: $e');
    }
  }

  Future<void> _checkAllPermissions() async {
    final permissions = [
      PermissionType.notification,
      PermissionType.sensors,
      PermissionType.storage,
      PermissionType.scheduleExactAlarm,
    ];

    for (final permissionType in permissions) {
      final status = await _getPermissionStatus(permissionType);
      _permissionCache[permissionType] = status;
    }
  }

  Future<PermissionStatus> _getPermissionStatus(PermissionType type) async {
    try {
      switch (type) {
        case PermissionType.notification:
          return await Permission.notification.status;
        case PermissionType.sensors:
          return Platform.isAndroid 
              ? await Permission.sensors.status 
              : PermissionStatus.granted;
        case PermissionType.storage:
          if (Platform.isAndroid) {
            final androidInfo = await _getAndroidVersion();
            if (androidInfo >= 33) {
              return await Permission.photos.status;
            } else {
              return await Permission.storage.status;
            }
          }
          return await Permission.storage.status;
        case PermissionType.camera:
          return await Permission.camera.status;
        case PermissionType.location:
          return await Permission.location.status;
        case PermissionType.scheduleExactAlarm:
          return Platform.isAndroid 
              ? await Permission.scheduleExactAlarm.status
              : PermissionStatus.granted;
      }
    } catch (e) {
      debugPrint('❌ Error checking permission $type: $e');
      return PermissionStatus.denied;
    }
  }

  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    
    try {
      final version = Platform.operatingSystemVersion;
      return int.tryParse(version.split('.').first) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // TEK SEFERLİK İZİN İSTEME - SADECE SENSÖR İÇİN
  Future<bool> requestEssentialPermissions(BuildContext context) async {
    // Sensor permission'ı sadece bir kez iste
    bool alreadyAsked = _prefs?.getBool(_sensorPermissionAsked) ?? false;
    
    if (!alreadyAsked) {
      final sensorStatus = await _getPermissionStatus(PermissionType.sensors);
      
      if (sensorStatus != PermissionStatus.granted) {
        await _requestSensorPermission(context);
        await _prefs?.setBool(_sensorPermissionAsked, true);
      }
    }
    
    return true;
  }

  Future<void> _requestSensorPermission(BuildContext context) async {
    try {
      final shouldRequest = await _showSensorPermissionDialog(context);
      
      if (shouldRequest) {
        final status = Platform.isAndroid 
            ? await Permission.sensors.request()
            : PermissionStatus.granted;
            
        _permissionCache[PermissionType.sensors] = status;
        
        if (status == PermissionStatus.granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Sensör izni verildi - Adım sayar aktif'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Sensor permission error: $e');
    }
  }

  Future<bool> _showSensorPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sensors, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Sensör İzni'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adım sayısını otomatik olarak takip etmek için hareket sensörü izni gerekiyor.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              '💪 Otomatik adım takibi ile fitness hedeflerinizi kolayca takip edin!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Geç'),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop(true);
            },
            child: const Text('İzin Ver'),
          ),
        ],
      ),
    ) ?? false;
  }

  bool isPermissionGranted(PermissionType type) {
    return _permissionCache[type] == PermissionStatus.granted;
  }

  Map<PermissionType, PermissionStatus> getAllPermissionStatuses() {
    return Map.from(_permissionCache);
  }

  String getPermissionStatusText(PermissionType type) {
    final status = _permissionCache[type];
    switch (status) {
      case PermissionStatus.granted:
        return 'İzin verildi';
      case PermissionStatus.denied:
        return 'İzin reddedildi';
      case PermissionStatus.restricted:
        return 'Kısıtlı';
      case PermissionStatus.limited:
        return 'Sınırlı';
      case PermissionStatus.permanentlyDenied:
        return 'Kalıcı olarak reddedildi';
      case PermissionStatus.provisional:
        return 'Geçici izin';
      case null:
        return 'Bilinmiyor';
    }
  }

  // Test için - izin geçmişini sıfırla
  Future<void> resetPermissionHistory() async {
    await _prefs?.remove(_sensorPermissionAsked);
    debugPrint('🔄 Permission history reset');
  }
}