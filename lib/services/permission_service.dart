// lib/services/permission_service.dart - COMPREHENSIVE PERMISSION MANAGER
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

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

  // Permission status cache
  final Map<PermissionType, PermissionStatus> _permissionCache = {};
  bool _isInitialized = false;

  /// Initialize permission service
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      await _checkAllPermissions();
      _isInitialized = true;
      debugPrint('✅ Permission service initialized');
    } catch (e) {
      debugPrint('❌ Permission service init error: $e');
    }
  }

  /// Check all required permissions
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

  /// Get permission status for a specific type
  Future<PermissionStatus> _getPermissionStatus(PermissionType type) async {
    try {
      switch (type) {
        case PermissionType.notification:
          return await Permission.notification.status;
        case PermissionType.sensors:
          return Platform.isAndroid 
              ? await Permission.sensors.status 
              : PermissionStatus.granted; // iOS doesn't need sensor permission
        case PermissionType.storage:
          if (Platform.isAndroid) {
            final androidInfo = await _getAndroidVersion();
            if (androidInfo >= 33) {
              // Android 13+ uses specific media permissions
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

  /// Get Android version
  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    
    try {
      final version = await _getSystemVersion();
      return int.tryParse(version.split('.').first) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get system version
  Future<String> _getSystemVersion() async {
    try {
      if (Platform.isAndroid) {
        return Platform.operatingSystemVersion;
      }
      return Platform.operatingSystemVersion;
    } catch (e) {
      return '0';
    }
  }

  /// Request permission with user-friendly dialog
  Future<PermissionStatus> requestPermission(
    BuildContext context,
    PermissionType type, {
    String? customMessage,
  }) async {
    try {
      // Check current status
      final currentStatus = await _getPermissionStatus(type);
      
      if (currentStatus == PermissionStatus.granted) {
        return currentStatus;
      }

      // Show rationale if needed
      if (currentStatus == PermissionStatus.denied) {
        final shouldRequest = await _showPermissionRationale(context, type, customMessage);
        if (!shouldRequest) {
          return currentStatus;
        }
      }

      // Handle permanently denied
      if (currentStatus == PermissionStatus.permanentlyDenied) {
        await _showSettingsDialog(context, type);
        return currentStatus;
      }

      // Request permission
      final newStatus = await _requestPermissionDirect(type);
      _permissionCache[type] = newStatus;

      // Show result feedback
      await _showPermissionResult(context, type, newStatus);

      return newStatus;
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
      return PermissionStatus.denied;
    }
  }

  /// Direct permission request
  Future<PermissionStatus> _requestPermissionDirect(PermissionType type) async {
    switch (type) {
      case PermissionType.notification:
        return await Permission.notification.request();
      case PermissionType.sensors:
        return Platform.isAndroid 
            ? await Permission.sensors.request()
            : PermissionStatus.granted;
      case PermissionType.storage:
        if (Platform.isAndroid) {
          final androidVersion = await _getAndroidVersion();
          if (androidVersion >= 33) {
            return await Permission.photos.request();
          }
        }
        return await Permission.storage.request();
      case PermissionType.camera:
        return await Permission.camera.request();
      case PermissionType.location:
        return await Permission.location.request();
      case PermissionType.scheduleExactAlarm:
        return Platform.isAndroid 
            ? await Permission.scheduleExactAlarm.request()
            : PermissionStatus.granted;
    }
  }

  /// Show permission rationale dialog
  Future<bool> _showPermissionRationale(
    BuildContext context,
    PermissionType type,
    String? customMessage,
  ) async {
    final info = _getPermissionInfo(type);
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(info.icon, color: info.color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${info.title} İzni',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customMessage ?? info.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: info.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: info.color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info.benefit,
                      style: TextStyle(
                        fontSize: 14,
                        color: info.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
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

  /// Show settings dialog for permanently denied permissions
  Future<void> _showSettingsDialog(BuildContext context, PermissionType type) async {
    final info = _getPermissionInfo(type);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Ayarlar Gerekli'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${info.title} izni kalıcı olarak reddedildi. Bu özelliği kullanmak için ayarlardan izin vermeniz gerekiyor.',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ayarlar > ${info.title} > İzin Ver',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Ayarları Aç'),
          ),
        ],
      ),
    );
  }

  /// Show permission result feedback
  Future<void> _showPermissionResult(
    BuildContext context,
    PermissionType type,
    PermissionStatus status,
  ) async {
    final info = _getPermissionInfo(type);
    
    if (status == PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('${info.title} izni verildi'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Get permission information
  PermissionInfo _getPermissionInfo(PermissionType type) {
    switch (type) {
      case PermissionType.notification:
        return PermissionInfo(
          title: 'Bildirim',
          description: 'Hatırlatıcılar ve motivasyon mesajları göndermek için bildirim izni gerekiyor.',
          benefit: 'Hedeflerinizi kaçırmayın!',
          icon: Icons.notifications,
          color: Colors.blue,
        );
      case PermissionType.sensors:
        return PermissionInfo(
          title: 'Sensör',
          description: 'Adım sayısını otomatik olarak takip etmek için hareket sensörü izni gerekiyor.',
          benefit: 'Otomatik adım takibi',
          icon: Icons.sensors,
          color: Colors.green,
        );
      case PermissionType.storage:
        return PermissionInfo(
          title: 'Depolama',
          description: 'Fotoğraflarınızı kaydetmek ve ilerleme resimlerini yönetmek için depolama izni gerekiyor.',
          benefit: 'Fotoğraf kaydetme',
          icon: Icons.photo_library,
          color: Colors.purple,
        );
      case PermissionType.camera:
        return PermissionInfo(
          title: 'Kamera',
          description: 'İlerleme fotoğrafları çekmek için kamera izni gerekiyor.',
          benefit: 'İlerlemenizi görsel olarak takip edin',
          icon: Icons.camera_alt,
          color: Colors.orange,
        );
      case PermissionType.location:
        return PermissionInfo(
          title: 'Konum',
          description: 'Dış mekan aktivitelerinizi takip etmek için konum izni gerekiyor.',
          benefit: 'GPS tabanlı aktivite takibi',
          icon: Icons.location_on,
          color: Colors.red,
        );
      case PermissionType.scheduleExactAlarm:
        return PermissionInfo(
          title: 'Zamanlanmış Bildirim',
          description: 'Tam zamanında hatırlatma bildirimleri göndermek için bu izin gerekiyor.',
          benefit: 'Kesin zamanlı hatırlatmalar',
          icon: Icons.alarm,
          color: Colors.indigo,
        );
    }
  }

  /// Check if permission is granted
  bool isPermissionGranted(PermissionType type) {
    return _permissionCache[type] == PermissionStatus.granted;
  }

  /// Get all permission statuses
  Map<PermissionType, PermissionStatus> getAllPermissionStatuses() {
    return Map.from(_permissionCache);
  }

  /// Request multiple permissions
  Future<Map<PermissionType, PermissionStatus>> requestMultiplePermissions(
    BuildContext context,
    List<PermissionType> permissions,
  ) async {
    final results = <PermissionType, PermissionStatus>{};
    
    for (final permission in permissions) {
      final status = await requestPermission(context, permission);
      results[permission] = status;
    }
    
    return results;
  }

  /// Essential permissions for the app
  Future<bool> requestEssentialPermissions(BuildContext context) async {
    final essentialPermissions = [
      PermissionType.notification,
      PermissionType.sensors,
    ];

    final results = await requestMultiplePermissions(context, essentialPermissions);
    
    // Check if all essential permissions are granted
    return results.values.every((status) => status == PermissionStatus.granted);
  }

  /// Refresh permission cache
  Future<void> refreshPermissions() async {
    await _checkAllPermissions();
  }

  /// Get permission status text for UI
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
}

/// Permission information class
class PermissionInfo {
  final String title;
  final String description;
  final String benefit;
  final IconData icon;
  final Color color;

  PermissionInfo({
    required this.title,
    required this.description,
    required this.benefit,
    required this.icon,
    required this.color,
  });
}