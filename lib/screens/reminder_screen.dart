// lib/screens/reminder_screen.dart - SESLİ BİLDİRİM + NAVİGASYON DÜZELTMESİ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder_model.dart';
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
    
    ReminderType selectedType = existingReminder?.type ?? ReminderType.general;
    DateTime selectedDate = existingReminder?.reminderDateTime ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(existingReminder?.reminderDateTime ?? DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // ÖNEMLİ: Modal SafeArea kullanacak
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24, // +24 navigasyon bar için
                top: 20, 
                left: 20, 
                right: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEditing ? 'Hatırlatıcıyı Düzenle' : 'Yeni Hatırlatıcı',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Başlık', border: OutlineInputBorder()),
                        validator: (value) => (value == null || value.isEmpty) ? 'Lütfen bir başlık girin.' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ReminderType>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Hatırlatıcı Türü', border: OutlineInputBorder()),
                        items: ReminderType.values.map((type) {
                          return DropdownMenuItem(value: type, child: Text(_getReminderTypeName(type)));
                        }).toList(),
                        onChanged: (type) => setDialogState(() => selectedType = type!),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2101));
                                if (picked != null) setDialogState(() => selectedDate = picked);
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(context: context, initialTime: selectedTime);
                                if (picked != null) setDialogState(() => selectedTime = picked);
                              },
                              icon: const Icon(Icons.access_time),
                              label: Text(selectedTime.format(context)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
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
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(isEditing ? 'Güncelle' : 'Kaydet'),
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

  // YENİ: Async yapıldı - sesli bildirim için
  Future<void> _saveReminder({
    required Reminder? existingReminder,
    required String title,
    required ReminderType type,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    final reminderDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (!isEditing(existingReminder) && reminderDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçmiş bir zamana hatırlatma ekleyemezsiniz.'), backgroundColor: AppColors.error));
      return;
    }

    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    
    if (isEditing(existingReminder)) {
      final updatedReminder = existingReminder!;
      updatedReminder.title = title;
      updatedReminder.type = type;
      updatedReminder.reminderDateTime = reminderDateTime;
      await reminderProvider.updateReminder(updatedReminder); // YENİ: await eklendi
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatırlatıcı güncellendi ve sesli bildirim zamanlandı! 🔔'), backgroundColor: AppColors.success),
      );
    } else {
      final newReminder = Reminder(
        title: title,
        type: type,
        reminderDateTime: reminderDateTime,
      );
      await reminderProvider.addReminder(newReminder); // YENİ: await eklendi
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatırlatıcı eklendi ve sesli bildirim zamanlandı! 🔔'), backgroundColor: AppColors.success),
      );
    }
    
    Navigator.pop(context);
  }

  bool isEditing(Reminder? reminder) => reminder != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hatırlatıcılar'),
        actions: [
          // YENİ: Test bildirimi butonu
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Test Bildirimi Gönder',
            onPressed: () async {
              final provider = Provider.of<ReminderProvider>(context, listen: false);
              await provider.sendTestNotification();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test bildirimi gönderildi! 🧪'), backgroundColor: AppColors.success),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        bottom: true, // ÖNEMLİ: Navigasyon barının üstünde kal
        child: Consumer<ReminderProvider>(
          builder: (context, provider, child) {
            if (provider.reminders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Henüz hatırlatıcı eklenmedi.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hatırlatıcı ekleyince sesli bildirim alacaksın! 🔔',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: provider.reminders.length,
              itemBuilder: (context, index) {
                final reminder = provider.reminders[index];
                final isPastReminder = reminder.reminderDateTime.isBefore(DateTime.now());
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: reminder.isActive 
                      ? (isPastReminder ? Colors.orange.withOpacity(0.1) : Theme.of(context).cardColor)
                      : Colors.grey.withOpacity(0.3),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        Icon(
                          reminder.icon, 
                          color: reminder.isActive 
                              ? (isPastReminder ? Colors.orange : AppColors.primaryGreen)
                              : Colors.grey,
                          size: 28,
                        ),
                        // YENİ: Bildirim ikonu
                        if (reminder.isActive && !isPastReminder)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      reminder.title,
                      style: TextStyle(
                        decoration: !reminder.isActive ? TextDecoration.lineThrough : null,
                        fontWeight: isPastReminder ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMMMEEEE, HH:mm', 'tr_TR').format(reminder.reminderDateTime),
                          style: TextStyle(
                            color: isPastReminder ? Colors.orange : null,
                          ),
                        ),
                        // YENİ: Bildirim durumu göster
                        if (reminder.isActive && !isPastReminder)
                          const Text(
                            '🔔 Sesli bildirim zamanlandı',
                            style: TextStyle(fontSize: 12, color: AppColors.primaryGreen),
                          )
                        else if (isPastReminder)
                          const Text(
                            '⏰ Geçmiş hatırlatma',
                            style: TextStyle(fontSize: 12, color: Colors.orange),
                          ),
                      ],
                    ),
                    trailing: Switch(
                      value: reminder.isActive,
                      onChanged: (value) async {
                        await provider.toggleReminderStatus(reminder.id, value);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(value 
                                ? 'Hatırlatıcı aktif edildi ve sesli bildirim zamanlandı! 🔔' 
                                : 'Hatırlatıcı pasif edildi ve sesli bildirim iptal edildi! 🔕'),
                            backgroundColor: value ? AppColors.success : AppColors.error,
                          ),
                        );
                      },
                      activeColor: AppColors.primaryGreen,
                    ),
                    onTap: () => _showAddOrEditReminderDialog(existingReminder: reminder),
                    onLongPress: () => _showDeleteDialog(reminder), // YENİ: Uzun basınca sil
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOrEditReminderDialog,
        child: const Icon(Icons.add),
        tooltip: 'Yeni Hatırlatıcı Ekle',
      ),
    );
  }

  // YENİ: Silme dialog'u
  void _showDeleteDialog(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hatırlatıcıyı Sil'),
        content: Text('${reminder.title} hatırlatıcısını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              await Provider.of<ReminderProvider>(context, listen: false).deleteReminder(reminder.id);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hatırlatıcı silindi ve sesli bildirim iptal edildi! 🗑️'), backgroundColor: AppColors.error),
              );
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getReminderTypeName(ReminderType type) {
    switch (type) {
      case ReminderType.sport:
        return 'Spor';
      case ReminderType.water:
        return 'Su İçme';
      case ReminderType.medication:
        return 'İlaç';
      case ReminderType.general:
        return 'Genel Görev';
    }
  }
}