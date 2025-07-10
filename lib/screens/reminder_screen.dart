// lib/screens/reminder_screen.dart - BİLDİRİM AYARLARI EKLİ
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hatırlatıcılar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.notifications), text: 'Bildirim Ayarları'),
            Tab(icon: Icon(Icons.schedule), text: 'Hatırlatıcılarım'),
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

  // BİLDİRİM AYARLARI SEKMESİ
  Widget _buildNotificationSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Su İçme Hatırlatmaları
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
              _buildIntervalSelector('Su hatırlatma aralığı', 'water'),
              _buildTimeRangeSelector('Su hatırlatma saatleri', 'water'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Vitamin Hatırlatmaları
          _buildNotificationSection(
            title: '💊 Vitamin Hatırlatmaları',
            subtitle: 'Spor vitaminlerini unutma',
            children: [
              _buildNotificationToggle(
                'Vitamin hatırlatmalarını etkinleştir',
                'vitamin',
                () => NotificationService().toggleReminderType('vitamin', true),
                () => NotificationService().toggleReminderType('vitamin', false),
              ),
              _buildVitaminReminders(),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Spor Hatırlatmaları
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
              _buildVitaminReminders(),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Adım Hatırlatmaları
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
              _buildStepReminderSettings(),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Test Bildirimi
          _buildTestNotificationButton(),
        ],
      ),
    );
  }

  // HATIRLATICILARIM SEKMESİ
  Widget _buildRemindersTab() {
    return Consumer<ReminderProvider>(
      builder: (context, provider, child) {
        if (provider.reminders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Henüz hatırlatıcı eklenmedi.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
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
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: reminder.isActive ? AppColors.primaryGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  child: Icon(
                    reminder.icon, 
                    color: reminder.isActive ? AppColors.primaryGreen : Colors.grey,
                  ),
                ),
                title: Text(
                  reminder.title,
                  style: TextStyle(
                    decoration: !reminder.isActive ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(reminder.reminderDateTime)),
                    Text(
                      _getReminderTypeName(reminder.type),
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: reminder.isActive,
                      onChanged: (value) {
                        provider.toggleReminderStatus(reminder.id, value);
                      },
                      activeColor: AppColors.primaryGreen,
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Düzenle'),
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
                        if (value == 'edit') {
                          _showAddOrEditReminderDialog(existingReminder: reminder);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(reminder);
                        }
                      },
                    ),
                  ],
                ),
                onTap: () => _showAddOrEditReminderDialog(existingReminder: reminder),
              ),
            );
          },
        );
      },
    );
  }

  // BİLDİRİM BÖLÜMÜ WIDGET'I
  Widget _buildNotificationSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // BİLDİRİM AÇMA/KAPAMA TOGGLE'I
  Widget _buildNotificationToggle(
    String title,
    String type,
    VoidCallback onEnable,
    VoidCallback onDisable,
  ) {
    return FutureBuilder<bool>(
      future: Future.value(NotificationService().isReminderEnabled(type)),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        return SwitchListTile(
          title: Text(title),
          value: isEnabled,
          onChanged: (value) {
            setState(() {
              if (value) {
                onEnable();
              } else {
                onDisable();
              }
            });
          },
          activeColor: AppColors.primaryGreen,
        );
      },
    );
  }

  // SU HATIRLATMA ARALIĞI SEÇİCİ
  Widget _buildIntervalSelector(String title, String type) {
    return ListTile(
      title: Text(title),
      subtitle: Text('Her 2 saatte bir'),
      trailing: DropdownButton<int>(
        value: 2,
        items: [1, 2, 3, 4, 6].map((hours) {
          return DropdownMenuItem(
            value: hours,
            child: Text('$hours saat'),
          );
        }).toList(),
        onChanged: (value) {
          // TODO: Interval ayarını kaydet
        },
      ),
    );
  }

  // SU HATIRLATMA SAAT ARALIĞI SEÇİCİ
  Widget _buildTimeRangeSelector(String title, String type) {
    return ListTile(
      title: Text(title),
      subtitle: Text('08:00 - 22:00 arası'),
      trailing: TextButton(
        onPressed: () {
          _showTimeRangeDialog();
        },
        child: Text('Değiştir'),
      ),
    );
  }

  // VİTAMİN HATIRLATMALARI
  Widget _buildVitaminReminders() {
    return Column(
      children: [
        ListTile(
          title: Text('Spor vitaminleri hatırlatması'),
          subtitle: Text('Seçtiğin vitaminleri zamanında al'),
          trailing: Switch(
            value: true,
            onChanged: (value) {},
            activeColor: AppColors.primaryGreen,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showVitaminSelectionDialog(),
          icon: Icon(Icons.medication_liquid),
          label: Text('Vitamin Hatırlatması Ekle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.withOpacity(0.1),
            foregroundColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  // ADIM HATIRLATMA AYARLARI
  Widget _buildStepReminderSettings() {
    return ListTile(
      title: Text('Günlük hedef: 10,000 adım'),
      subtitle: Text('Akşam 20:00\'da hatırlat'),
      trailing: Icon(Icons.edit, color: AppColors.primaryGreen),
      onTap: () {
        _showStepReminderDialog();
      },
    );
  }

  // TEST BİLDİRİMİ BUTONU
  Widget _buildTestNotificationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          NotificationService().sendTestNotification();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Test bildirimi gönderildi!'),
              backgroundColor: AppColors.success,
            ),
          );
        },
        icon: Icon(Icons.notifications_active),
        label: Text('Test Bildirimi Gönder'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // SAAT ARALIĞI DİYALOGU
  void _showTimeRangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Su İçme Saatleri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Başlangıç Saati'),
              subtitle: Text('08:00'),
              trailing: Icon(Icons.access_time),
              onTap: () {
                // TODO: Saat seçici göster
              },
            ),
            ListTile(
              title: Text('Bitiş Saati'),
              subtitle: Text('22:00'),
              trailing: Icon(Icons.access_time),
              onTap: () {
                // TODO: Saat seçici göster
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // VİTAMİN SEÇİM DİYALOGU
  void _showVitaminSelectionDialog() {
    VitaminType selectedVitamin = VitaminType.vitaminD;
    String customVitaminName = '';
    String dosage = '';
    bool withFood = false;
    TimeOfDay selectedTime = TimeOfDay(hour: 9, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('💊 Vitamin Hatırlatması Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<VitaminType>(
                  decoration: InputDecoration(
                    labelText: 'Vitamin Türü',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedVitamin,
                  items: VitaminType.values.map((vitamin) {
                    return DropdownMenuItem(
                      value: vitamin,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(Reminder.getVitaminTypeName(vitamin)),
                          Text(
                            Reminder.getVitaminDescription(vitamin),
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedVitamin = value!;
                    });
                  },
                ),
                
                if (selectedVitamin == VitaminType.custom) ...[
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Özel Vitamin Adı',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => customVitaminName = value,
                  ),
                ],
                
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Doz (örn: 1000mg, 2 tablet)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => dosage = value,
                ),
                
                SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Yemekle birlikte al'),
                  subtitle: Text('Mide rahatsızlığını önler'),
                  value: withFood,
                  onChanged: (value) {
                    setDialogState(() {
                      withFood = value;
                    });
                  },
                  activeColor: AppColors.primaryGreen,
                ),
                
                SizedBox(height: 16),
                ListTile(
                  title: Text('Hatırlatma Saati'),
                  subtitle: Text(selectedTime.format(context)),
                  trailing: Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                _addVitaminReminder(
                  vitaminType: selectedVitamin,
                  customName: customVitaminName,
                  dosage: dosage,
                  withFood: withFood,
                  time: selectedTime,
                );
                Navigator.pop(context);
              },
              child: Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  // VİTAMİN HATIRLATMASI EKLEME
  void _addVitaminReminder({
    required VitaminType vitaminType,
    required String customName,
    required String dosage,
    required bool withFood,
    required TimeOfDay time,
  }) {
    final now = DateTime.now();
    final reminderDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    String title = vitaminType == VitaminType.custom 
        ? customName.isNotEmpty ? customName : 'Özel Vitamin'
        : Reminder.getVitaminTypeName(vitaminType);
    
    if (dosage.isNotEmpty) {
      title += ' ($dosage)';
    }
    
    String description = Reminder.getVitaminDescription(vitaminType);
    if (withFood) {
      description += ' - Yemekle birlikte alın';
    }

    final vitaminReminder = Reminder(
      title: title,
      description: description,
      type: ReminderType.vitamin,
      reminderDateTime: reminderDateTime,
      repeatInterval: RepeatInterval.daily, // Günlük tekrar
      vitaminType: vitaminType,
      vitaminWithFood: withFood,
    );

    Provider.of<ReminderProvider>(context, listen: false).addReminder(vitaminReminder);
    
    // Bildirimi zamanla
    NotificationService().scheduleNotification(
      id: vitaminReminder.id.hashCode,
      title: '💊 $title Zamanı!',
      body: withFood ? 'Vitaminini yemekle birlikte almayı unutma!' : 'Vitamin alma zamanı!',
      scheduledTime: reminderDateTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title hatırlatması eklendi!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  // ADIM HATIRLATMASI DİYALOGU
  void _showStepReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adım Hedefi Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Günlük Hedef'),
              initialValue: '10000',
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('Hatırlatma Saati'),
              subtitle: Text('20:00'),
              trailing: Icon(Icons.access_time),
              onTap: () {
                // TODO: Saat seçici
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // SİLME ONAYLAMASI
  void _showDeleteConfirmation(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hatırlatıcıyı Sil'),
        content: Text('Bu hatırlatıcıyı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<ReminderProvider>(context, listen: false).deleteReminder(reminder.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }

  // ESKİ HATIRLATICI EKLEME/DÜZENLEME DİYALOGU (FLOATING BUTTON İÇİN)
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

    if (existingReminder == null && reminderDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Geçmiş bir zamana hatırlatma ekleyemezsiniz.'), backgroundColor: AppColors.error));
      return;
    }

    final reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    
    if (existingReminder != null) {
      final updatedReminder = existingReminder;
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
      
      // Bildirimi zamanla
      NotificationService().scheduleNotification(
        id: newReminder.id.hashCode,
        title: newReminder.title,
        body: 'Hatırlatıcı zamanı!',
        scheduledTime: reminderDateTime,
      );
    }
    
    Navigator.pop(context);
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
}