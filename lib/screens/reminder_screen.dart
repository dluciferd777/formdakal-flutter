// lib/screens/reminder_screen.dart - KARTLAR KÜÇÜLTÜLDÜ
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reminder_provider.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../utils/colors.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  
  TimeOfDay _sportsReminderTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentIndex) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(() {});
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hatırlatıcılar'),
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: isDarkMode ? 0 : 2,
        centerTitle: true,
        actions: [
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Yeni Hatırlatıcı Ekle',
              onPressed: () => _showAddOrEditReminderDialog(),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.settings, size: 20), text: 'Genel Ayarlar'),
            Tab(icon: Icon(Icons.schedule, size: 20), text: 'Hatırlatıcılarım'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationSettingsTab(),
          _buildRemindersTab(),
        ],
      ),
    );
  }

  // BİLDİRİM AYARLARI SEKMESİ - KÜÇÜLTÜLMÜŞ KARTLAR
  Widget _buildNotificationSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12), // 16'dan 12'ye düşürüldü
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationSection(
            title: '💧 Su İçme Hatırlatmaları',
            subtitle: 'Düzenli su içmenizi hatırlatır',
            children: [
              _buildNotificationToggle(
                'Su hatırlatmalarını etkinleştir',
                'water',
                () => NotificationService().toggleReminderType('water', true),
                () => NotificationService().toggleReminderType('water', false),
              ),
            ],
          ),
          const SizedBox(height: 16), // 24'ten 16'ya düşürüldü
          _buildNotificationSection(
            title: '💊 Vitamin Hatırlatmaları',
            subtitle: 'Vitamin ve takviyelerini unutma',
            children: [
              _buildNotificationToggle(
                'Vitamin hatırlatmalarını etkinleştir',
                'vitamin',
                () => NotificationService().toggleReminderType('vitamin', true),
                () => NotificationService().toggleReminderType('vitamin', false),
              ),
              const SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showVitaminSelectionDialog(),
                  icon: const Icon(Icons.medication_liquid, size: 18), // İkon küçültüldü
                  label: const Text('Vitamin Hatırlatması Ekle', style: TextStyle(fontSize: 13)), // Yazı küçültüldü
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding küçültüldü
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNotificationSection(
            title: '💪 Spor Hatırlatmaları',
            subtitle: 'Egzersiz yapmayı unutmamanız için',
            children: [
              _buildNotificationToggle(
                'Spor hatırlatmalarını etkinleştir',
                'workout',
                () => NotificationService().toggleReminderType('workout', true),
                () => NotificationService().toggleReminderType('workout', false),
              ),
              const Divider(height: 16), // 24'ten 16'ya düşürüldü
              _buildSportsReminderSettings(),
            ],
          ),
          const SizedBox(height: 16),
          _buildNotificationSection(
            title: '🦶 Adım Hatırlatmaları',
            subtitle: 'Günlük adım hedefinizi hatırlatır',
            children: [
              _buildNotificationToggle(
                'Adım hatırlatmalarını etkinleştir',
                'step',
                () => NotificationService().toggleReminderType('step', true),
                () => NotificationService().toggleReminderType('step', false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // HATIRLATICILARIM SEKMESİ
  Widget _buildRemindersTab() {
    return Consumer<ReminderProvider>(
      builder: (context, provider, child) {
        if (provider.reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Henüz hatırlatıcı eklenmedi.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                Text('Eklemek için sağ üstteki + ikonuna dokunun.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12.0), // 16'dan 12'ye düşürüldü
          itemCount: provider.reminders.length,
          itemBuilder: (context, index) {
            final reminder = provider.reminders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8), // 12'den 8'e düşürüldü
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Padding küçültüldü
                leading: CircleAvatar(
                  radius: 18, // 20'den 18'e küçültüldü
                  backgroundColor: reminder.isActive ? AppColors.primaryGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  child: Icon(
                    reminder.icon, 
                    color: reminder.isActive ? AppColors.primaryGreen : Colors.grey,
                    size: 18, // İkon küçültüldü
                  ),
                ),
                title: Text(
                  reminder.title, 
                  style: TextStyle(
                    decoration: !reminder.isActive ? TextDecoration.lineThrough : null, 
                    fontWeight: FontWeight.w600,
                    fontSize: 14, // Yazı küçültüldü
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(reminder.reminderDateTime),
                  style: const TextStyle(fontSize: 12), // Yazı küçültüldü
                ),
                trailing: Switch(
                  value: reminder.isActive,
                  onChanged: (value) => provider.toggleReminderStatus(reminder.id, value),
                  activeColor: AppColors.primaryGreen,
                ),
                onTap: () => _showAddOrEditReminderDialog(existingReminder: reminder),
              ),
            );
          },
        );
      },
    );
  }

  // WIDGET BUILDER METOTLARI - KÜÇÜLTÜLMÜŞ
  Widget _buildNotificationSection({required String title, required String subtitle, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(12), // 16'dan 12'ye düşürüldü
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16, // Yazı küçültüldü
            ),
          ),
          Text(
            subtitle, 
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: 13, // Yazı küçültüldü
            ),
          ),
          const Divider(height: 16), // 24'ten 16'ya düşürüldü
          ...children,
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(String title, String type, VoidCallback onEnable, VoidCallback onDisable) {
    return FutureBuilder<bool>(
      future: Future.value(NotificationService().isReminderEnabled(type)),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        return SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(fontSize: 14), // Yazı küçültüldü
          ),
          value: isEnabled,
          onChanged: (value) {
            setState(() {
              if (value) onEnable(); else onDisable();
            });
          },
          activeColor: AppColors.primaryGreen,
          contentPadding: EdgeInsets.zero, // Padding kaldırıldı
        );
      },
    );
  }

  Widget _buildSportsReminderSettings() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text(
        'Hatırlatma Saati',
        style: TextStyle(fontSize: 14), // Yazı küçültüldü
      ),
      trailing: TextButton(
        onPressed: () async {
          final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _sportsReminderTime);
          if (picked != null && picked != _sportsReminderTime) {
            setState(() {
              _sportsReminderTime = picked;
              
              final now = DateTime.now();
              DateTime scheduledDate = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
              if (scheduledDate.isBefore(now)) {
                 scheduledDate = scheduledDate.add(const Duration(days: 1));
              }

              NotificationService().scheduleNotification(
                id: 1,
                title: '💪 Egzersiz Zamanı!',
                body: 'Harekete geçme zamanı, spor seni bekliyor!',
                scheduledTime: scheduledDate,
              );
            });
          }
        },
        child: Text(
          _sportsReminderTime.format(context), 
          style: const TextStyle(fontSize: 15), // Yazı küçültüldü
        ),
      ),
    );
  }

  // DİYALOG METOTLARI
  void _showVitaminSelectionDialog() {
    VitaminType selectedVitamin = VitaminType.vitaminD;
    String dosage = '';
    bool withFood = false;
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('💊 Vitamin Hatırlatması Ekle', style: TextStyle(fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<VitaminType>(
                  decoration: const InputDecoration(
                    labelText: 'Vitamin Türü', 
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Küçültüldü
                  ),
                  value: selectedVitamin,
                  items: VitaminType.values.map((vitamin) => DropdownMenuItem(
                    value: vitamin, 
                    child: Text(
                      Reminder.getVitaminTypeName(vitamin),
                      style: const TextStyle(fontSize: 14), // Yazı küçültüldü
                    ),
                  )).toList(),
                  onChanged: (value) => setDialogState(() => selectedVitamin = value!),
                ),
                const SizedBox(height: 12), // 16'dan 12'ye
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Doz (örn: 1000mg, 2 tablet)', 
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Küçültüldü
                  ),
                  style: const TextStyle(fontSize: 14), // Yazı küçültüldü
                  onChanged: (value) => dosage = value,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text(
                    'Yemekle birlikte al',
                    style: TextStyle(fontSize: 14), // Yazı küçültüldü
                  ),
                  value: withFood,
                  onChanged: (value) => setDialogState(() => withFood = value),
                  activeColor: AppColors.primaryGreen,
                  contentPadding: EdgeInsets.zero, // Padding kaldırıldı
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text(
                    'Hatırlatma Saati',
                    style: TextStyle(fontSize: 14), // Yazı küçültüldü
                  ),
                  subtitle: Text(
                    selectedTime.format(context),
                    style: const TextStyle(fontSize: 13), // Yazı küçültüldü
                  ),
                  trailing: const Icon(Icons.access_time, size: 20), // İkon küçültüldü
                  contentPadding: EdgeInsets.zero, // Padding kaldırıldı
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: selectedTime);
                    if (picked != null) setDialogState(() => selectedTime = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('İptal', style: TextStyle(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () {
                final reminderDateTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, selectedTime.hour, selectedTime.minute);
                String title = Reminder.getVitaminTypeName(selectedVitamin);
                if (dosage.isNotEmpty) title += ' ($dosage)';

                final newReminder = Reminder(
                  title: title,
                  type: ReminderType.vitamin,
                  reminderDateTime: reminderDateTime,
                  vitaminType: selectedVitamin,
                  vitaminWithFood: withFood,
                );
                Provider.of<ReminderProvider>(context, listen: false).addReminder(newReminder);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Küçültüldü
              ),
              child: const Text('Ekle', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOrEditReminderDialog({Reminder? existingReminder}) {
    final isEditing = existingReminder != null;
    final titleController = TextEditingController(text: existingReminder?.title ?? '');
    ReminderType selectedType = existingReminder?.type ?? ReminderType.general;
    DateTime selectedDate = existingReminder?.reminderDateTime ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(existingReminder?.reminderDateTime ?? DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, 
              top: 16, // 20'den 16'ya
              left: 16, // 20'den 16'ya
              right: 16, // 20'den 16'ya
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEditing ? 'Hatırlatıcıyı Düzenle' : 'Yeni Hatırlatıcı', 
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18), // Yazı küçültüldü
                  ),
                  const SizedBox(height: 16), // 20'den 16'ya
                  TextFormField(
                    controller: titleController, 
                    decoration: const InputDecoration(
                      labelText: 'Başlık', 
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Küçültüldü
                    ),
                    style: const TextStyle(fontSize: 14), // Yazı küçültüldü
                  ),
                  const SizedBox(height: 12), // 16'dan 12'ye
                  DropdownButtonFormField<ReminderType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Hatırlatıcı Türü', 
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Küçültüldü
                    ),
                    items: ReminderType.values.map((type) => DropdownMenuItem(
                      value: type, 
                      child: Text(
                        _getReminderTypeName(type),
                        style: const TextStyle(fontSize: 14), // Yazı küçültüldü
                      ),
                    )).toList(),
                    onChanged: (type) => setDialogState(() => selectedType = type!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context, 
                              initialDate: selectedDate, 
                              firstDate: DateTime.now(), 
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) setDialogState(() => selectedDate = picked);
                          }, 
                          icon: const Icon(Icons.calendar_today, size: 18), // İkon küçültüldü
                          label: Text(
                            DateFormat('dd.MM.yyyy').format(selectedDate),
                            style: const TextStyle(fontSize: 13), // Yazı küçültüldü
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Küçültüldü
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // 10'dan 8'e
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: selectedTime);
                            if (picked != null) setDialogState(() => selectedTime = picked);
                          }, 
                          icon: const Icon(Icons.access_time, size: 18), // İkon küçültüldü
                          label: Text(
                            selectedTime.format(context),
                            style: const TextStyle(fontSize: 13), // Yazı küçültüldü
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Küçültüldü
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // 20'den 16'ya
                  ElevatedButton(
                    onPressed: () {
                      _saveReminder(
                        existingReminder: existingReminder,
                        title: titleController.text,
                        type: selectedType,
                        date: selectedDate,
                        time: selectedTime,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44), // 50'den 44'e küçültüldü
                      padding: const EdgeInsets.symmetric(vertical: 12), // Küçültüldü
                    ),
                    child: Text(
                      isEditing ? 'Güncelle' : 'Kaydet',
                      style: const TextStyle(fontSize: 15), // Yazı küçültüldü
                    ),
                  ),
                  const SizedBox(height: 16), // 20'den 16'ya
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveReminder({required Reminder? existingReminder, required String title, required ReminderType type, required DateTime date, required TimeOfDay time}) {
    final reminderDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);

    if (existingReminder != null) {
      existingReminder.title = title;
      existingReminder.type = type;
      existingReminder.reminderDateTime = reminderDateTime;
      reminderProvider.updateReminder(existingReminder);
    } else {
      final newReminder = Reminder(title: title, type: type, reminderDateTime: reminderDateTime);
      reminderProvider.addReminder(newReminder);
    }
    Navigator.pop(context);
  }

  String _getReminderTypeName(ReminderType type) {
    switch (type) {
      case ReminderType.sport: return 'Spor';
      case ReminderType.water: return 'Su İçme';
      case ReminderType.medication: return 'İlaç';
      case ReminderType.vitamin: return 'Vitamin';
      case ReminderType.general: return 'Genel Görev';
    }
  }
}