// lib/screens/reminder_screen.dart - MODERN APPLE/GOOGLE TARZI
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ReminderScreenState extends State<ReminderScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _showAddOrEditReminderDialog({Reminder? existingReminder}) {
    final isEditing = existingReminder != null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReminderFormSheet(
        existingReminder: existingReminder,
        isEditing: isEditing,
      ),
    );
  }

  void _showTestNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.science_rounded, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Text('Test Bildirimi'),
          ],
        ),
        content: const Text('Bildirim sistemi çalışıyor mu test etmek ister misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<ReminderProvider>(context, listen: false).sendTestNotification();
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Test bildirimi gönderildi!'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Test Et'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF2F2F7),
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        title: const Text(
          'Hatırlatıcılar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_rounded),
            onPressed: _showTestNotificationDialog,
            tooltip: 'Test Bildirimi',
          ),
        ],
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, provider, child) {
          if (provider.reminders.isEmpty) {
            return _buildEmptyState(isDarkMode);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Yaklaşan Hatırlatmalar
              _buildUpcomingSection(provider, isDarkMode),
              
              // Tüm Hatırlatmalar
              _buildAllRemindersSection(provider, isDarkMode),
              
              // Bottom Padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showAddOrEditReminderDialog();
          },
          backgroundColor: AppColors.primaryGreen,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Hatırlatıcı Ekle',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Henüz Hatırlatıcın Yok',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'İlk hatırlatıcını ekleyerek\nhedeflerine ulaşmaya başla!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showAddOrEditReminderDialog();
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('İlk Hatırlatıcını Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSection(ReminderProvider provider, bool isDarkMode) {
    final upcomingReminders = provider.getUpcomingReminders().take(3).toList();
    
    if (upcomingReminders.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Yaklaşan Hatırlatmalar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: upcomingReminders.length,
              itemBuilder: (context, index) {
                final reminder = upcomingReminders[index];
                return _buildUpcomingCard(reminder, isDarkMode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(Reminder reminder, bool isDarkMode) {
    final timeUntil = reminder.reminderDateTime.difference(DateTime.now());
    final isToday = reminder.reminderDateTime.day == DateTime.now().day;
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  reminder.icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                isToday ? 'Bugün' : DateFormat('MMM dd').format(reminder.reminderDateTime),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reminder.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            DateFormat('HH:mm').format(reminder.reminderDateTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (timeUntil.inHours < 24)
            Text(
              '${timeUntil.inHours}s ${timeUntil.inMinutes % 60}dk sonra',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllRemindersSection(ReminderProvider provider, bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tüm Hatırlatmalar',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '${provider.reminders.length} hatırlatma',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: provider.reminders.length,
            itemBuilder: (context, index) {
              final reminder = provider.reminders[index];
              return _buildReminderCard(reminder, provider, isDarkMode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder, ReminderProvider provider, bool isDarkMode) {
    return Dismissible(
      key: Key(reminder.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        HapticFeedback.heavyImpact();
        provider.deleteReminder(reminder.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDarkMode ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: reminder.isActive 
                  ? _getReminderTypeColor(reminder.type).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              reminder.icon,
              color: reminder.isActive 
                  ? _getReminderTypeColor(reminder.type)
                  : Colors.grey,
              size: 24,
            ),
          ),
          title: Text(
            reminder.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
              decoration: reminder.isActive 
                  ? TextDecoration.none 
                  : TextDecoration.lineThrough,
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
                  color: _getReminderTypeColor(reminder.type),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('dd MMMM EEEE, HH:mm', 'tr_TR').format(reminder.reminderDateTime),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          trailing: Switch.adaptive(
            value: reminder.isActive,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              provider.toggleReminderStatus(reminder.id, value);
            },
            activeColor: _getReminderTypeColor(reminder.type),
          ),
          onTap: () {
            HapticFeedback.selectionClick();
            _showAddOrEditReminderDialog(existingReminder: reminder);
          },
        ),
      ),
    );
  }

  Color _getReminderTypeColor(ReminderType type) {
    switch (type) {
      case ReminderType.sport:
        return AppColors.primaryGreen;
      case ReminderType.water:
        return Colors.blue;
      case ReminderType.medication:
        return Colors.red;
      case ReminderType.general:
        return Colors.orange;
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
      case ReminderType.general:
        return 'Genel';
    }
  }
}

// Modern Form Sheet Widget
class _ReminderFormSheet extends StatefulWidget {
  final Reminder? existingReminder;
  final bool isEditing;

  const _ReminderFormSheet({
    this.existingReminder,
    required this.isEditing,
  });

  @override
  State<_ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<_ReminderFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  
  late ReminderType _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late RepeatInterval _repeatInterval;
  List<int> _customRepeatDays = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingReminder?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existingReminder?.description ?? '');
    _selectedType = widget.existingReminder?.type ?? ReminderType.general;
    _selectedDate = widget.existingReminder?.reminderDateTime ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(widget.existingReminder?.reminderDateTime ?? DateTime.now());
    _repeatInterval = widget.existingReminder?.repeatInterval ?? RepeatInterval.none;
    _customRepeatDays = widget.existingReminder?.customRepeatDays ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                widget.isEditing ? 'Hatırlatıcıyı Düzenle' : 'Yeni Hatırlatıcı',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Hatırlatıcı başlığı girin',
                  prefixIcon: const Icon(Icons.title_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen bir başlık girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  hintText: 'Hatırlatıcı açıklaması',
                  prefixIcon: const Icon(Icons.description_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Type Selection
              DropdownButtonFormField<ReminderType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(_getTypeIcon(_selectedType)),
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
                        Text(_getTypeName(type)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (type) => setState(() => _selectedType = type!),
              ),
              const SizedBox(height: 20),
              
              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeButton(
                      context,
                      'Tarih',
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      Icons.calendar_today_rounded,
                      () => _selectDate(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateTimeButton(
                      context,
                      'Saat',
                      _selectedTime.format(context),
                      Icons.access_time_rounded,
                      () => _selectTime(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Repeat Options
              DropdownButtonFormField<RepeatInterval>(
                value: _repeatInterval,
                decoration: InputDecoration(
                  labelText: 'Tekrar',
                  prefixIcon: const Icon(Icons.repeat_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: RepeatInterval.values.map((interval) {
                  return DropdownMenuItem(
                    value: interval,
                    child: Text(_getRepeatName(interval)),
                  );
                }).toList(),
                onChanged: (interval) => setState(() => _repeatInterval = interval!),
              ),
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.isEditing ? 'Güncelle' : 'Kaydet',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeButton(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveReminder() {
    if (!_formKey.currentState!.validate()) return;

    final reminderDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (!widget.isEditing && reminderDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Geçmiş bir zamana hatırlatma ekleyemezsiniz.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final provider = Provider.of<ReminderProvider>(context, listen: false);

    if (widget.isEditing) {
      final updatedReminder = widget.existingReminder!;
      updatedReminder.title = _titleController.text.trim();
      updatedReminder.description = _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim();
      updatedReminder.type = _selectedType;
      updatedReminder.reminderDateTime = reminderDateTime;
      updatedReminder.repeatInterval = _repeatInterval;
      updatedReminder.customRepeatDays = _customRepeatDays.isEmpty ? null : _customRepeatDays;
      provider.updateReminder(updatedReminder);
    } else {
      final newReminder = Reminder(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        type: _selectedType,
        reminderDateTime: reminderDateTime,
        repeatInterval: _repeatInterval,
        customRepeatDays: _customRepeatDays.isEmpty ? null : _customRepeatDays,
      );
      provider.addReminder(newReminder);
    }

    Navigator.pop(context);
    HapticFeedback.heavyImpact(); // successNotificationFeedback → heavyImpact
  }

  IconData _getTypeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.sport:
        return Icons.fitness_center_rounded;
      case ReminderType.water:
        return Icons.water_drop_rounded;
      case ReminderType.medication:
        return Icons.medical_services_rounded;
      case ReminderType.general:
        return Icons.task_alt_rounded;
    }
  }

  String _getTypeName(ReminderType type) {
    switch (type) {
      case ReminderType.sport:
        return 'Spor & Egzersiz';
      case ReminderType.water:
        return 'Su İçme';
      case ReminderType.medication:
        return 'İlaç & Sağlık';
      case ReminderType.general:
        return 'Genel Görev';
    }
  }

  String _getRepeatName(RepeatInterval interval) {
    switch (interval) {
      case RepeatInterval.none:
        return 'Tek Seferlik';
      case RepeatInterval.daily:
        return 'Her Gün';
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