// lib/screens/reminder_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder_model.dart';
import '../utils/colors.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _showTestPanel = false;

  void _showAddOrEditReminderDialog({Reminder? existingReminder}) {
    final isEditing = existingReminder != null;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existingReminder?.title ?? '');
    
    ReminderType selectedType = existingReminder?.type ?? ReminderType.general;
    DateTime selectedDate = existingReminder?.reminderDateTime ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(existingReminder?.reminderDateTime ?? DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20, left: 20, right: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Başlık
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEditing ? 'Hatırlatıcıyı Düzenle' : 'Yeni Hatırlatıcı',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Başlık alanı
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Hatırlatıcı Başlığı',
                          hintText: 'Örn: Vitamin D al, Spor yap',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(
                            _getIconForType(selectedType),
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        validator: (value) => (value == null || value.isEmpty) 
                            ? 'Lütfen bir başlık girin.' 
                            : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Tür seçimi
                      DropdownButtonFormField<ReminderType>(
                        value: selectedType,
                        decoration: InputDecoration(
                          labelText: 'Hatırlatıcı Türü',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(
                            Icons.category_rounded,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        items: ReminderType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(_getIconForType(type), size: 20),
                                const SizedBox(width: 8),
                                Text(_getReminderTypeName(type)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (type) => setDialogState(() => selectedType = type!),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tarih ve saat seçimi
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setDialogState(() => selectedDate = picked);
                                }
                              },
                              icon: const Icon(Icons.calendar_today_rounded),
                              label: Text(
                                DateFormat('dd.MM.yyyy').format(selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setDialogState(() => selectedTime = picked);
                                }
                              },
                              icon: const Icon(Icons.access_time_rounded),
                              label: Text(
                                selectedTime.format(context),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Kaydet butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              _saveReminder(
                                existingReminder: existingReminder,
                                title: titleController.text,
                                type: selectedType,
                                date: selectedDate,
                                time: selectedTime,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isEditing ? 'Güncelle' : 'Kaydet',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _saveReminder({
    required Reminder? existingReminder,
    required String title,
    required ReminderType type,
    required DateTime date,
    required TimeOfDay time,
  }) {
    final reminderDateTime = DateTime(
      date.year, 
      date.month, 
      date.day, 
      time.hour, 
      time.minute
    );

    if (!isEditing(existingReminder) && reminderDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçmiş bir zamana hatırlatma ekleyemezsiniz.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    
    if (isEditing(existingReminder)) {
      final updatedReminder = existingReminder!;
      updatedReminder.title = title;
      updatedReminder.type = type;
      updatedReminder.reminderDateTime = reminderDateTime;
      reminderProvider.updateReminder(updatedReminder);
    } else {
      final newReminder = Reminder(
        title: title,
        type: type,
        reminderDateTime: reminderDateTime,
      );
      reminderProvider.addReminder(newReminder);
    }
    
    Navigator.pop(context);
    
    // Başarı mesajı
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing(existingReminder) 
              ? 'Hatırlatıcı güncellendi! 🔔'
              : 'Hatırlatıcı eklendi! 🔔',
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool isEditing(Reminder? reminder) => reminder != null;

  IconData _getIconForType(ReminderType type) {
    switch (type) {
      case ReminderType.sport:
        return Icons.fitness_center_rounded;
      case ReminderType.water:
        return Icons.water_drop_rounded;
      case ReminderType.medication:
        return Icons.medical_services_rounded;
      case ReminderType.vitamin: // EKLENEN CASE
        return Icons.medical_services_rounded;
      case ReminderType.general:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.alarm_rounded,
                color: AppColors.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Hatırlatıcılar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showTestPanel = !_showTestPanel;
              });
            },
            icon: Icon(
              _showTestPanel ? Icons.close_rounded : Icons.bug_report_rounded,
              color: AppColors.primaryGreen,
            ),
            tooltip: _showTestPanel ? 'Test Panelini Kapat' : 'Test Panelini Aç',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Consumer<ReminderProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                // Test paneli (geliştirme amaçlı)
                if (_showTestPanel) _buildTestPanel(),
                
                // Ana içerik
                Expanded(
                  child: provider.reminders.isEmpty 
                      ? _buildEmptyState(isDark)
                      : _buildRemindersList(provider, isDark),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOrEditReminderDialog,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Yeni Hatırlatıcı',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.alarm_off_rounded,
                size: 60,
                color: AppColors.primaryGreen.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz Hatırlatıcı Yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vitamin, spor ve diğer önemli görevleriniz\niçin hatırlatıcı ekleyin!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _showAddOrEditReminderDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('İlk Hatırlatıcını Ekle'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersList(ReminderProvider provider, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.reminders.length,
      itemBuilder: (context, index) {
        final reminder = provider.reminders[index];
        return _buildReminderCard(reminder, provider, isDark);
      },
    );
  }

  Widget _buildReminderCard(Reminder reminder, ReminderProvider provider, bool isDark) {
    final isActive = reminder.isActive;
    final isPast = reminder.reminderDateTime.isBefore(DateTime.now());
    
    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_rounded,
              color: Colors.white,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              'Sil',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Hatırlatıcıyı Sil'),
            content: Text('${reminder.title} hatırlatıcısını silmek istediğinizden emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sil', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        provider.deleteReminder(reminder.id);
        _showSnackBar('✅ Hatırlatıcı silindi!');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive 
                ? AppColors.primaryGreen.withOpacity(0.3)
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          boxShadow: [
            if (isActive) BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive 
                  ? _getColorForType(reminder.type).withOpacity(0.1)
                  : (isDark ? Colors.grey[700] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForType(reminder.type),
              color: isActive 
                  ? _getColorForType(reminder.type)
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
              size: 24,
            ),
          ),
          title: Text(
            reminder.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: !isActive ? TextDecoration.lineThrough : null,
              color: isActive 
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                _getReminderTypeName(reminder.type),
                style: TextStyle(
                  fontSize: 12,
                  color: _getColorForType(reminder.type),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(reminder.reminderDateTime),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  if (isPast && isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Geçmiş',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // YENİ EKLENDİ: Kaydır ve sil ipucu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swipe_left_rounded,
                      size: 12,
                      color: Colors.red[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sola kaydır = Sil',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: isActive,
                onChanged: (value) {
                  provider.toggleReminderStatus(reminder.id, value);
                },
                activeColor: AppColors.primaryGreen,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showAddOrEditReminderDialog(existingReminder: reminder);
                      break;
                    case 'delete':
                      _showDeleteDialog(reminder, provider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Düzenle'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Sil', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              // YENİ EKLENDİ: Direkt silme butonu
              IconButton(
                onPressed: () => _showDeleteDialog(reminder, provider),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 22,
                ),
                tooltip: 'Sil',
              ),
            ],
          ),
          onTap: () => _showAddOrEditReminderDialog(existingReminder: reminder),
        ),
      ),
    );
  }

  Widget _buildTestPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Bildirim Test Paneli',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTestButton('Anında Test', () async {
                await _notificationService.sendTestNotification();
                _showSnackBar('Test bildirimi gönderildi!');
              }),
              _buildTestButton('5sn Sonra Vitamin', () async {
                await _notificationService.scheduleVitaminReminder(
                  id: 9998,
                  vitaminName: 'Test Vitamini',
                  scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
                );
                _showSnackBar('Vitamin hatırlatması 5 saniye sonra!');
              }),
              _buildTestButton('10sn Sonra Spor', () async {
                await _notificationService.scheduleWorkoutReminder(
                  id: 9997,
                  workoutType: 'Test Sporcu',
                  scheduledTime: DateTime.now().add(const Duration(seconds: 10)),
                );
                _showSnackBar('Spor hatırlatması 10 saniye sonra!');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.withOpacity(0.2),
        foregroundColor: Colors.orange[800],
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  void _showDeleteDialog(Reminder reminder, ReminderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Hatırlatıcıyı Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu hatırlatıcıyı silmek istediğinizden emin misiniz?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getIconForType(reminder.type),
                    color: _getColorForType(reminder.type),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _getReminderTypeName(reminder.type),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getColorForType(reminder.type),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ Bu işlem geri alınamaz ve zamanlanmış bildirim de iptal edilecektir.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteReminder(reminder.id);
              Navigator.pop(context);
              _showSnackBar('✅ Hatırlatıcı silindi!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Sil',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForType(ReminderType type) {
    switch (type) {
      case ReminderType.sport:
        return Colors.orange;
      case ReminderType.water:
        return Colors.blue;
      case ReminderType.medication:
        return Colors.green;
      case ReminderType.vitamin: // EKLENEN CASE
        return Colors.purple;
      case ReminderType.general:
        return AppColors.primaryGreen;
    }
  }

  String _getReminderTypeName(ReminderType type) {
    switch (type) {
      case ReminderType.sport:
        return 'Spor';
      case ReminderType.water:
        return 'Su İçme';
      case ReminderType.medication:
        return 'İlaç';
      case ReminderType.vitamin: // EKLENEN CASE
        return 'Vitamin';
      case ReminderType.general:
        return 'Genel';
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
} // EKSIK PARANTEZ EKLENDİ