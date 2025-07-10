// lib/services/cloud_backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

enum CloudPlatform {
  googleDrive,  // Android
  iCloudDrive,  // iOS
  none,         // Platform desteklenmiyor
}

class CloudBackupService {
  static final CloudBackupService _instance = CloudBackupService._internal();
  factory CloudBackupService() => _instance;
  CloudBackupService._internal();

  static const MethodChannel _channel = MethodChannel('com.formdakal.cloud_backup');
  
  // Platform belirleme
  CloudPlatform get currentPlatform {
    if (!kIsWeb) {
      if (Platform.isAndroid) return CloudPlatform.googleDrive;
      if (Platform.isIOS) return CloudPlatform.iCloudDrive;
    }
    return CloudPlatform.none;
  }

  // Yedekleme verilerini hazırla
  Future<Map<String, dynamic>> _prepareBackupData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Tüm app verilerini topla
    final backupData = <String, dynamic>{};
    
    // SharedPreferences verilerini al
    final keys = prefs.getKeys();
    for (final key in keys) {
      final value = prefs.get(key);
      if (value != null) {
        backupData[key] = value;
      }
    }
    
    // Metadata ekle
    backupData['_backup_metadata'] = {
      'app_version': '1.0.0',
      'backup_date': DateTime.now().toIso8601String(),
      'platform': currentPlatform.toString(),
      'data_version': '1.0',
    };
    
    return backupData;
  }

  // Google Drive'a yedekleme (Android)
  Future<bool> _backupToGoogleDrive(Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      
      final result = await _channel.invokeMethod('backupToGoogleDrive', {
        'data': jsonString,
        'fileName': 'formdakal_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      });
      
      return result['success'] ?? false;
    } catch (e) {
      print('❌ Google Drive yedekleme hatası: $e');
      return false;
    }
  }

  // iCloud Drive'a yedekleme (iOS)
  Future<bool> _backupToICloudDrive(Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      
      final result = await _channel.invokeMethod('backupToICloudDrive', {
        'data': jsonString,
        'fileName': 'formdakal_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      });
      
      return result['success'] ?? false;
    } catch (e) {
      print('❌ iCloud Drive yedekleme hatası: $e');
      return false;
    }
  }

  // Yerel dosyaya yedekleme (fallback)
  Future<bool> _backupToLocalFile(Map<String, dynamic> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/formdakal_backup.json');
      
      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);
      
      print('✅ Yerel yedekleme tamamlandı: ${file.path}');
      return true;
    } catch (e) {
      print('❌ Yerel yedekleme hatası: $e');
      return false;
    }
  }

  // Ana yedekleme fonksiyonu
  Future<BackupResult> createBackup() async {
    try {
      print('🔄 Yedekleme başlatılıyor...');
      
      // Verileri hazırla
      final backupData = await _prepareBackupData();
      
      bool success = false;
      String message = '';
      CloudPlatform usedPlatform = currentPlatform;
      
      // Platform'a göre yedekleme
      switch (currentPlatform) {
        case CloudPlatform.googleDrive:
          success = await _backupToGoogleDrive(backupData);
          message = success ? 'Google Drive\'a yedeklendi' : 'Google Drive yedekleme başarısız';
          break;
          
        case CloudPlatform.iCloudDrive:
          success = await _backupToICloudDrive(backupData);
          message = success ? 'iCloud Drive\'a yedeklendi' : 'iCloud Drive yedekleme başarısız';
          break;
          
        case CloudPlatform.none:
          // Fallback: Yerel dosyaya kaydet
          success = await _backupToLocalFile(backupData);
          message = success ? 'Yerel dosyaya yedeklendi' : 'Yedekleme başarısız';
          usedPlatform = CloudPlatform.none;
          break;
      }
      
      // Son yedekleme tarihini kaydet
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_backup_date', DateTime.now().toIso8601String());
        await prefs.setString('last_backup_platform', usedPlatform.toString());
      }
      
      return BackupResult(
        success: success,
        message: message,
        platform: usedPlatform,
        backupDate: DateTime.now(),
        dataSize: jsonEncode(backupData).length,
      );
      
    } catch (e) {
      print('❌ Yedekleme genel hatası: $e');
      return BackupResult(
        success: false,
        message: 'Yedekleme sırasında hata: $e',
        platform: CloudPlatform.none,
        backupDate: DateTime.now(),
        dataSize: 0,
      );
    }
  }

  // Google Drive'dan geri yükleme
  Future<List<BackupFile>> _listGoogleDriveBackups() async {
    try {
      final result = await _channel.invokeMethod('listGoogleDriveBackups');
      final List<dynamic> files = result['files'] ?? [];
      
      return files.map((file) => BackupFile.fromJson(file)).toList();
    } catch (e) {
      print('❌ Google Drive liste hatası: $e');
      return [];
    }
  }

  // iCloud Drive'dan geri yükleme
  Future<List<BackupFile>> _listICloudDriveBackups() async {
    try {
      final result = await _channel.invokeMethod('listICloudDriveBackups');
      final List<dynamic> files = result['files'] ?? [];
      
      return files.map((file) => BackupFile.fromJson(file)).toList();
    } catch (e) {
      print('❌ iCloud Drive liste hatası: $e');
      return [];
    }
  }

  // Mevcut yedekleme dosyalarını listele
  Future<List<BackupFile>> listAvailableBackups() async {
    switch (currentPlatform) {
      case CloudPlatform.googleDrive:
        return await _listGoogleDriveBackups();
      case CloudPlatform.iCloudDrive:
        return await _listICloudDriveBackups();
      case CloudPlatform.none:
        return await _listLocalBackups();
    }
  }

  // Yerel yedekleme dosyalarını listele
  Future<List<BackupFile>> _listLocalBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .where((file) => file.path.contains('formdakal_backup'))
          .cast<File>();
      
      return files.map((file) {
        final stat = file.statSync();
        return BackupFile(
          name: file.path.split('/').last,
          size: stat.size,
          modifiedDate: stat.modified,
          platform: CloudPlatform.none,
        );
      }).toList();
    } catch (e) {
      print('❌ Yerel dosya liste hatası: $e');
      return [];
    }
  }

  // Belirli bir yedekleme dosyasını geri yükle
  Future<RestoreResult> restoreFromBackup(BackupFile backupFile) async {
    try {
      print('🔄 Geri yükleme başlatılıyor: ${backupFile.name}');
      
      String? backupData;
      
      // Platform'a göre veri çek
      switch (backupFile.platform) {
        case CloudPlatform.googleDrive:
          final result = await _channel.invokeMethod('downloadFromGoogleDrive', {
            'fileName': backupFile.name,
          });
          backupData = result['data'];
          break;
          
        case CloudPlatform.iCloudDrive:
          final result = await _channel.invokeMethod('downloadFromICloudDrive', {
            'fileName': backupFile.name,
          });
          backupData = result['data'];
          break;
          
        case CloudPlatform.none:
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/${backupFile.name}');
          if (await file.exists()) {
            backupData = await file.readAsString();
          }
          break;
      }
      
      if (backupData == null) {
        return RestoreResult(success: false, message: 'Yedekleme dosyası okunamadı');
      }
      
      // JSON verisini parse et
      final Map<String, dynamic> data = jsonDecode(backupData);
      
      // Metadata kontrolü
      final metadata = data['_backup_metadata'];
      if (metadata != null) {
        print('📋 Yedekleme bilgileri:');
        print('   App Version: ${metadata['app_version']}');
        print('   Backup Date: ${metadata['backup_date']}');
        print('   Platform: ${metadata['platform']}');
      }
      
      // SharedPreferences'ı temizle ve geri yükle
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Metadata hariç tüm verileri geri yükle
      for (final entry in data.entries) {
        if (entry.key == '_backup_metadata') continue;
        
        final value = entry.value;
        if (value is String) {
          await prefs.setString(entry.key, value);
        } else if (value is int) {
          await prefs.setInt(entry.key, value);
        } else if (value is double) {
          await prefs.setDouble(entry.key, value);
        } else if (value is bool) {
          await prefs.setBool(entry.key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(entry.key, value);
        }
      }
      
      // Geri yükleme tarihini kaydet
      await prefs.setString('last_restore_date', DateTime.now().toIso8601String());
      await prefs.setString('restored_from_platform', backupFile.platform.toString());
      
      return RestoreResult(
        success: true,
        message: 'Veriler başarıyla geri yüklendi',
        restoredItemsCount: data.length - 1, // metadata hariç
      );
      
    } catch (e) {
      print('❌ Geri yükleme hatası: $e');
      return RestoreResult(success: false, message: 'Geri yükleme hatası: $e');
    }
  }

  // Son yedekleme bilgisini al
  Future<BackupInfo?> getLastBackupInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackupDate = prefs.getString('last_backup_date');
      final lastBackupPlatform = prefs.getString('last_backup_platform');
      
      if (lastBackupDate != null) {
        return BackupInfo(
          lastBackupDate: DateTime.parse(lastBackupDate),
          platform: CloudPlatform.values.firstWhere(
            (p) => p.toString() == lastBackupPlatform,
            orElse: () => CloudPlatform.none,
          ),
        );
      }
      
      return null;
    } catch (e) {
      print('❌ Son yedekleme bilgisi hatası: $e');
      return null;
    }
  }

  // Otomatik yedekleme ayarı
  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', enabled);
    
    if (enabled) {
      await prefs.setString('auto_backup_interval', 'daily'); // weekly, monthly
    }
  }

  // Otomatik yedekleme kontrolü
  Future<bool> shouldCreateAutoBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('auto_backup_enabled') ?? false;
      
      if (!isEnabled) return false;
      
      final lastBackupDate = prefs.getString('last_backup_date');
      if (lastBackupDate == null) return true;
      
      final lastBackup = DateTime.parse(lastBackupDate);
      final daysSinceLastBackup = DateTime.now().difference(lastBackup).inDays;
      
      return daysSinceLastBackup >= 1; // Günlük kontrol
    } catch (e) {
      return false;
    }
  }
}

// Yedekleme sonucu modeli
class BackupResult {
  final bool success;
  final String message;
  final CloudPlatform platform;
  final DateTime backupDate;
  final int dataSize;

  BackupResult({
    required this.success,
    required this.message,
    required this.platform,
    required this.backupDate,
    required this.dataSize,
  });
}

// Geri yükleme sonucu modeli
class RestoreResult {
  final bool success;
  final String message;
  final int? restoredItemsCount;

  RestoreResult({
    required this.success,
    required this.message,
    this.restoredItemsCount,
  });
}

// Yedekleme dosyası modeli
class BackupFile {
  final String name;
  final int size;
  final DateTime modifiedDate;
  final CloudPlatform platform;

  BackupFile({
    required this.name,
    required this.size,
    required this.modifiedDate,
    required this.platform,
  });

  factory BackupFile.fromJson(Map<String, dynamic> json) {
    return BackupFile(
      name: json['name'],
      size: json['size'],
      modifiedDate: DateTime.parse(json['modifiedDate']),
      platform: CloudPlatform.values.firstWhere(
        (p) => p.toString() == json['platform'],
        orElse: () => CloudPlatform.none,
      ),
    );
  }

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// Yedekleme bilgisi modeli
class BackupInfo {
  final DateTime lastBackupDate;
  final CloudPlatform platform;

  BackupInfo({
    required this.lastBackupDate,
    required this.platform,
  });

  String get platformName {
    switch (platform) {
      case CloudPlatform.googleDrive:
        return 'Google Drive';
      case CloudPlatform.iCloudDrive:
        return 'iCloud Drive';
      case CloudPlatform.none:
        return 'Yerel Dosya';
    }
  }
}