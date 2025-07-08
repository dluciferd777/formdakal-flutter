// lib/screens/reminder_screen.dart
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

  void _saveReminder({
    required Reminder? existingReminder,
    required String title,
    required ReminderType type,
    required DateTime date,
    required TimeOfDay time,
  }) {
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
  }

  bool isEditing(Reminder? reminder) => reminder != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hatırlatıcılar'),
      ),
      body: SafeArea( // Burası eklendi
        child: Consumer<ReminderProvider>(
          builder: (context, provider, child) {
            if (provider.reminders.isEmpty) {
              return const Center(
                child: Text(
                  'Henüz hatırlatıcı eklenmedi.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: provider.reminders.length,
              itemBuilder: (context, index) {
                final reminder = provider.reminders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16), // Kartlar arası boşluk artırıldı
                  color: reminder.isActive ? Theme.of(context).cardColor : Colors.grey.withOpacity(0.3),
                  child: ListTile(
                    leading: Icon(reminder.icon, color: reminder.isActive ? AppColors.primaryGreen : Colors.grey),
                    title: Text(
                      reminder.title,
                      style: TextStyle(
                        decoration: !reminder.isActive ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('dd MMMMEEEE, HH:mm', 'tr_TR').format(reminder.reminderDateTime), // Yıl ve saat de gösterildi
                    ),
                    trailing: Switch(
                      value: reminder.isActive,
                      onChanged: (value) {
                        provider.toggleReminderStatus(reminder.id, value);
                      },
                      activeColor: AppColors.primaryGreen,
                    ),
                    onTap: () => _showAddOrEditReminderDialog(existingReminder: reminder),
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
