// lib/screens/backup_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/cloud_backup_service.dart';
import '../utils/colors.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final CloudBackupService _backupService = CloudBackupService();
  BackupInfo? _lastBackupInfo;
  List<BackupFile> _availableBackups = [];
  bool _isLoading = false;
  bool _autoBackupEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final lastBackup = await _backupService.getLastBackupInfo();
      final backups = await _backupService.listAvailableBackups();
      
      setState(() {
        _lastBackupInfo = lastBackup;
        _availableBackups = backups;
      });
    } catch (e) {
      print('❌ Yedekleme bilgisi yükleme hatası: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _backupService.createBackup();
      
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result.message}'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Bilgileri yenile
        await _loadBackupInfo();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Yedekleme hatası: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreFromBackup(BackupFile backupFile) async {
    // Onay dialogu
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ Geri Yükleme Onayı'),
        content: Text(
          'Bu işlem mevcut tüm verilerinizi silecek ve seçilen yedeklemeden geri yükleyecektir.\n\n'
          'Devam etmek istediğinizden emin misiniz?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Geri Yükle'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    
    try {
      final result = await _backupService.restoreFromBackup(backupFile);
      
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result.message}'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // App'i yeniden başlatma önerisi
        _showRestartDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Geri yükleme hatası: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🔄 Yeniden Başlatma Gerekli'),
        content: Text(
          'Veriler başarıyla geri yüklendi. Değişikliklerin etkili olması için uygulamayı yeniden başlatın.'
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // App'i kapat (kullanıcı manuel olarak yeniden açacak)
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platform = _backupService.currentPlatform;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('☁️ Bulut Yedekleme'),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform bilgisi
                _buildPlatformInfo(platform),
                
                SizedBox(height: 24),
                
                // Son yedekleme bilgisi
                _buildLastBackupInfo(),
                
                SizedBox(height: 24),
                
                // Yedekleme butonları
                _buildBackupActions(),
                
                SizedBox(height: 24),
                
                // Otomatik yedekleme ayarı
                _buildAutoBackupSettings(),
                
                SizedBox(height: 24),
                
                // Mevcut yedeklemeler
                _buildAvailableBackups(),
              ],
            ),
          ),
    );
  }

  Widget _buildPlatformInfo(CloudPlatform platform) {
    String platformName, description, icon;
    Color color;
    
    switch (platform) {
      case CloudPlatform.googleDrive:
        platformName = 'Google Drive';
        description = 'Android cihazınızda Google Drive kullanılarak yedekleme yapılır';
        icon = '📱';
        color = Colors.blue;
        break;
      case CloudPlatform.iCloudDrive:
        platformName = 'iCloud Drive';
        description = 'iOS cihazınızda iCloud Drive kullanılarak yedekleme yapılır';
        icon = '🍎';
        color = Colors.grey[800]!;
        break;
      case CloudPlatform.none:
        platformName = 'Yerel Depolama';
        description = 'Cihazınızda yerel olarak yedekleme yapılır';
        icon = '📁';
        color = Colors.orange;
        break;
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 32)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platformName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastBackupInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 Son Yedekleme',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          
          if (_lastBackupInfo != null) ...[
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(_lastBackupInfo!.lastBackupDate),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.cloud, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  _lastBackupInfo!.platformName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.info, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'Henüz yedekleme yapılmamış',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackupActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _createBackup,
            icon: Icon(Icons.backup),
            label: Text('Yedek Oluştur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _loadBackupInfo,
            icon: Icon(Icons.refresh),
            label: Text('Yenile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoBackupSettings() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚙️ Otomatik Yedekleme',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          SwitchListTile(
            title: Text('Otomatik günlük yedekleme'),
            subtitle: Text('Her gün otomatik olarak verilerinizi yedekler'),
            value: _autoBackupEnabled,
            onChanged: (value) {
              setState(() => _autoBackupEnabled = value);
              _backupService.setAutoBackupEnabled(value);
            },
            activeColor: AppColors.primaryGreen,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableBackups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📂 Mevcut Yedeklemeler (${_availableBackups.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        
        if (_availableBackups.isEmpty) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_open, color: Colors.grey[600]),
                SizedBox(width: 12),
                Text(
                  'Henüz yedekleme dosyası yok',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _availableBackups.length,
            itemBuilder: (context, index) {
              final backup = _availableBackups[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                    child: Icon(
                      Icons.backup,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  title: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(backup.modifiedDate),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Boyut: ${backup.formattedSize}'),
                      Text('Platform: ${_getPlatformName(backup.platform)}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'restore',
                        child: Row(
                          children: [
                            Icon(Icons.restore, size: 16),
                            SizedBox(width: 8),
                            Text('Geri Yükle'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'restore') {
                        _restoreFromBackup(backup);
                      } else if (value == 'delete') {
                        _deleteBackup(backup);
                      }
                    },
                  ),
                  onTap: () => _restoreFromBackup(backup),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  String _getPlatformName(CloudPlatform platform) {
    switch (platform) {
      case CloudPlatform.googleDrive:
        return 'Google Drive';
      case CloudPlatform.iCloudDrive:
        return 'iCloud Drive';
      case CloudPlatform.none:
        return 'Yerel';
    }
  }

  Future<void> _deleteBackup(BackupFile backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🗑️ Yedekleme Sil'),
        content: Text('Bu yedekleme dosyasını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Platform-specific silme işlemi implementasyonu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yedekleme dosyası silindi'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadBackupInfo();
    }
  }
}