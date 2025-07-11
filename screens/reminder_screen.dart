// lib/screens/reminder_screen.dart - ÇALIŞAN VERSİYON
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reminder_provider.dart';
import '../providers/theme_provider.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../utils/colors.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  void _showAddOrEditReminderDialog({Reminder? existingReminder}) {
    final isEditing = existingReminder != null;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: existingReminder?.title ?? '');
    final descriptionController = TextEditingController(text: existingReminder?.description ?? '');
    
    ReminderType selectedType = existingReminder?.type ?? ReminderType.general;
    DateTime selectedDate = existingReminder?.reminderDateTime ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(existingReminder?.reminderDateTime ?? DateTime.now());
    RepeatInterval selectedRepeat = existingReminder?.repeatInterval ?? RepeatInterval.none;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            // MediaQuery.of(context).padding.bottom, alt navigasyon çubuğunun yüksekliğini verir.
            // MediaQuery.of(context).viewInsets.bottom, klavye açıkkenki yüksekliği verir.
            final double bottomPadding = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Hatırlatıcıyı Düzenle' : 'Yeni Hatırlatıcı',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  
                  // Form content - Scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Başlık
                            TextFormField(
                              controller: titleController,
                              decoration: InputDecoration(
                                labelText: 'Başlık *',
                                hintText: 'Hatırlatıcı başlığı girin',
                                prefixIcon: const Icon(Icons.title),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) => (value == null || value.isEmpty) 
                                  ? 'Lütfen bir başlık girin.' : null,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Açıklama
                            TextFormField(
                              controller: descriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Açıklama (Opsiyonel)',
                                hintText: 'Hatırlatıcı detayları...',
                                prefixIcon: const Icon(Icons.description),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Hatırlatıcı türü
                            DropdownButtonFormField<ReminderType>(
                              value: selectedType,
                              decoration: InputDecoration(
                                labelText: 'Hatırlatıcı Türü',
                                prefixIcon: Icon(_getTypeIcon(selectedType)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: ReminderType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Row(
                                    children: [
                                      Icon(_getTypeIcon(type), size: 20),
                                      const SizedBox(width: 8),
                                      Text(_getReminderTypeName(type)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (type) => setDialogState(() => selectedType = type!),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Tekrar durumu
                            DropdownButtonFormField<RepeatInterval>(
                              value: selectedRepeat,
                              decoration: InputDecoration(
                                labelText: 'Tekrar',
                                prefixIcon: const Icon(Icons.repeat),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: RepeatInterval.values.map((repeat) {
                                return DropdownMenuItem(
                                  value: repeat,
                                  child: Text(_getRepeatName(repeat)),
                                );
                              }).toList(),
                              onChanged: (repeat) => setDialogState(() => selectedRepeat = repeat!),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Tarih ve saat seçimi
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule, color: AppColors.primaryGreen),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Hatırlatma Zamanı',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              final picked = await showDatePicker(
                                                context: context, 
                                                initialDate: selectedDate, 
                                                firstDate: DateTime.now().subtract(const Duration(days: 1)), 
                                                lastDate: DateTime(2101),
                                                locale: const Locale('tr', 'TR'),
                                              );
                                              if (picked != null) {
                                                setDialogState(() => selectedDate = picked);
                                              }
                                            },
                                            icon: const Icon(Icons.calendar_today),
                                            label: Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(selectedDate)),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                            icon: const Icon(Icons.access_time),
                                            label: Text(selectedTime.format(context)),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Save button - Fixed at bottom
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding), // Alt padding eklendi
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isEditing) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _deleteReminder(existingReminder);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              label: const Text('Sil', style: TextStyle(color: AppColors.error)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: AppColors.error),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                _saveReminder(
                                  existingReminder: existingReminder,
                                  title: titleController.text.trim(),
                                  description: descriptionController.text.trim().isEmpty 
                                      ? null : descriptionController.text.trim(),
                                  type: selectedType,
                                  date: selectedDate,
                                  time: selectedTime,
                                  repeat: selectedRepeat,
                                );
                              }
                            },
                            icon: Icon(isEditing ? Icons.update : Icons.save),
                            label: Text(isEditing ? 'Güncelle' : 'Kaydet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
    required String? description,
    required ReminderType type,
    required DateTime date,
    required TimeOfDay time,
    required RepeatInterval repeat,
  }) async {
    final reminderDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    // Geçmiş zaman kontrolü (sadece yeni hatırlatıcılar için)
    if (existingReminder == null && reminderDateTime.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geçmiş bir zamana hatırlatma ekleyemezsiniz.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    
    try {
      if (existingReminder != null) {
        // Güncelleme
        final updatedReminder = Reminder(
          id: existingReminder.id,
          title: title,
          description: description,
          type: type,
          reminderDateTime: reminderDateTime,
          isActive: existingReminder.isActive,
          repeatInterval: repeat,
        );
        
        await reminderProvider.updateReminder(updatedReminder);
        
        // Mevcut bildirimi iptal et ve yenisini planla
        await NotificationService().cancelNotification(existingReminder.id.hashCode);
        await _scheduleNotification(updatedReminder);
        
      } else {
        // Yeni ekleme
        final newReminder = Reminder(
          title: title,
          description: description,
          type: type,
          reminderDateTime: reminderDateTime,
          repeatInterval: repeat,
        );
        
        await reminderProvider.addReminder(newReminder);
        
        // Bildirim planla
        await _scheduleNotification(newReminder);
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingReminder != null ? 'Hatırlatıcı güncellendi!' : 'Hatırlatıcı eklendi!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _deleteReminder(Reminder reminder) async {
    try {
      final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
      await reminderProvider.deleteReminder(reminder.id);
      
      // Bildirimi iptal et
      await NotificationService().cancelNotification(reminder.id.hashCode);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hatırlatıcı silindi!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _scheduleNotification(Reminder reminder) async {
    if (!reminder.isActive || reminder.reminderDateTime.isBefore(DateTime.now())) {
      return;
    }

    try {
      await NotificationService().scheduleNotification(
        id: reminder.id.hashCode,
        title: _getNotificationTitle(reminder.type),
        body: reminder.title,
        scheduledTime: reminder.reminderDateTime,
        payload: 'reminder_${reminder.id}',
      );
    } catch (e) {
      print('Bildirim zamanlama hatası: $e');
    }
  }

  String _getNotificationTitle(ReminderType type) {
    switch (type) {
      case ReminderType.sport:
        return '🏃‍♂️ Spor Zamanı!';
      case ReminderType.water:
        return '💧 Su İçme Hatırlatması';
      case ReminderType.medication:
        return '💊 İlaç Zamanı';
      case ReminderType.vitamin:
        return '🍊 Vitamin Zamanı';
      case ReminderType.general:
        return '📋 Hatırlatma';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.primaryGreen, // Temaya göre renk
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Hatırlatıcılar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode 
                  ? Icons.light_mode 
                  : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ReminderProvider>(
          builder: (context, provider, child) {
            if (provider.reminders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz hatırlatıcı eklenmedi.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'İlk hatırlatıcını eklemek için + butonuna dokun',
                      textAlign: TextAlign.center, // Metni ortala
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 16), // Yeni bilgi metni için boşluk
                    // YENİ BİLGİ METNİ
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Spor, su, vitamin, ilaç veya genel görevler için zamanlanmış bildirimler ekleyerek düzenli kal. Bildirimleri yönetmek için dokun.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.info, // Bilgi rengi kullanıldı
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.reminders.length,
              itemBuilder: (context, index) {
                final reminder = provider.reminders[index];
                return _buildReminderCard(reminder);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOrEditReminderDialog,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Hatırlatıcı Ekle'),
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    final now = DateTime.now();
    final isPast = reminder.reminderDateTime.isBefore(now);
    final isToday = reminder.reminderDateTime.year == now.year &&
                   reminder.reminderDateTime.month == now.month &&
                   reminder.reminderDateTime.day == now.day;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: reminder.isActive ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isToday && reminder.isActive 
              ? const BorderSide(color: AppColors.primaryGreen, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => _showAddOrEditReminderDialog(existingReminder: reminder),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: reminder.isActive 
                        ? AppColors.primaryGreen.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    reminder.icon,
                    color: reminder.isActive ? AppColors.primaryGreen : Colors.grey,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: !reminder.isActive ? TextDecoration.lineThrough : null,
                          color: !reminder.isActive ? Colors.grey : null,
                        ),
                      ),
                      
                      if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reminder.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      const SizedBox(height: 4),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: isToday ? AppColors.primaryGreen : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(reminder.reminderDateTime),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isToday ? AppColors.primaryGreen : Colors.grey.shade600,
                              fontWeight: isToday ? FontWeight.w600 : null,
                            ),
                          ),
                          if (isPast && reminder.isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Geçmiş',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Switch
                Switch(
                  value: reminder.isActive,
                  onChanged: (value) async {
                    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
                    await reminderProvider.toggleReminderStatus(reminder.id, value);
                    
                    if (value) {
                      // Aktif yapıldığında bildirim planla
                      await _scheduleNotification(reminder);
                    } else {
                      // Pasif yapıldığında bildirimi iptal et
                      await NotificationService().cancelNotification(reminder.id.hashCode);
                    }
                  },
                  activeColor: AppColors.primaryGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.sport:
        return Icons.sports_gymnastics;
      case ReminderType.water:
        return Icons.water_drop;
      case ReminderType.medication:
        return Icons.medical_services;
      case ReminderType.vitamin:
        return Icons.healing; // vitamins ikonu yok, healing kullan
      case ReminderType.general:
        return Icons.task;
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
      case ReminderType.vitamin:
        return 'Vitamin';
      case ReminderType.general:
        return 'Genel Görev';
    }
  }

  String _getRepeatName(RepeatInterval repeat) {
    switch (repeat) {
      case RepeatInterval.none:
        return 'Tek seferlik';
      case RepeatInterval.daily:
        return 'Her gün';
      case RepeatInterval.weekly:
        return 'Haftalık';
      case RepeatInterval.monthly:
        return 'Aylık';
      case RepeatInterval.yearly:
        return 'Yıllık';
      case RepeatInterval.custom:
        return 'Özel';
    }
  }
}
