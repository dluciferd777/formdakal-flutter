// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:formdakal/models/user_model.dart';
import 'package:formdakal/providers/theme_provider.dart';
import 'package:formdakal/providers/user_provider.dart';
import 'package:formdakal/services/calorie_service.dart';
import 'package:formdakal/utils/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _muscleController = TextEditingController();
  final _visceralFatController = TextEditingController();
  final _waterController = TextEditingController();
  final _metabolicAgeController = TextEditingController();
  final _boneController = TextEditingController();

  String? _selectedGender;
  String? _selectedActivityLevel;
  String? _selectedGoal;
  int? _selectedWeeklyWorkoutDays;

  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user.name;
      _ageController.text = user.age.toString();
      _heightController.text = user.height.toString();
      _weightController.text = user.weight.toString();
      _bodyFatController.text = user.bodyFatPercentage?.toString() ?? '';
      _muscleController.text = user.musclePercentage?.toString() ?? '';
      _visceralFatController.text = user.visceralFat?.toString() ?? '';
      _waterController.text = user.waterPercentage?.toString() ?? '';
      _metabolicAgeController.text = user.metabolicAge?.toString() ?? '';
      _boneController.text = user.bonePercentage?.toString() ?? '';
      
      _selectedGender = user.gender;
      _selectedActivityLevel = user.activityLevel;
      _selectedGoal = user.goal;
      _selectedWeeklyWorkoutDays = user.weeklyWorkoutDays;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // Animasyonu tekrarla

    _colorAnimation = ColorTween(
      begin: AppColors.primaryGreen.withOpacity(0.2),
      end: AppColors.primaryGreen.withOpacity(0.5),
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    _muscleController.dispose();
    _visceralFatController.dispose();
    _waterController.dispose();
    _metabolicAgeController.dispose();
    _boneController.dispose();
    _animationController.dispose(); // Animasyon controller'ı dispose et
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;
      if (currentUser == null) return;

      // HATA DÜZELTME: Virgül (,) ile girilen ondalık sayıları noktaya (.) çevir.
      double? parseOptionalDouble(String text) {
        if (text.isEmpty) return null;
        return double.tryParse(text.replaceAll(',', '.'));
      }

      final updatedUser = UserModel(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? currentUser.age,
        height: parseOptionalDouble(_heightController.text) ?? currentUser.height,
        weight: parseOptionalDouble(_weightController.text) ?? currentUser.weight,
        gender: _selectedGender!,
        activityLevel: _selectedActivityLevel!,
        goal: _selectedGoal!,
        weeklyWorkoutDays: _selectedWeeklyWorkoutDays!,
        profileImagePath: currentUser.profileImagePath,
        bodyFatPercentage: parseOptionalDouble(_bodyFatController.text),
        musclePercentage: parseOptionalDouble(_muscleController.text),
        visceralFat: parseOptionalDouble(_visceralFatController.text),
        waterPercentage: parseOptionalDouble(_waterController.text),
        metabolicAge: _metabolicAgeController.text.isNotEmpty ? int.tryParse(_metabolicAgeController.text) : null,
        bonePercentage: parseOptionalDouble(_boneController.text),
      );

      await userProvider.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _showImageOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profil Resmi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeriden Değiştir'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Resmi Sil'),
                onTap: () async {
                  Navigator.of(context).pop();
                  // mounted kontrolü eklendi
                  if (mounted) {
                    await Provider.of<UserProvider>(context, listen: false).deleteProfileImage();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        await Provider.of<UserProvider>(context, listen: false)
            .updateProfileImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim seçilemedi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            icon: Icon(context.watch<ThemeProvider>().isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.user == null) {
              return const Center(child: Text('Kullanıcı bilgileri yüklenemedi.'));
            }
            final user = userProvider.user!; // Kullanıcı objesini al
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showImageOptionsDialog,
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _colorAnimation,
                            builder: (context, child) {
                              return CircleAvatar(
                                radius: 60,
                                backgroundColor: _colorAnimation.value, // Animasyonlu renk
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: _buildProfileImage(userProvider.user?.profileImagePath),
                                  child: userProvider.user?.profileImagePath == null
                                      ? const Icon(Icons.person, size: 60, color: AppColors.primaryGreen)
                                      : null,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userProvider.user?.profileImagePath == null
                                ? 'Profil resmi eklemek için tıklayınız'
                                : 'Profil resmini değiştirmek için tıklayınız',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryGreen),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Temel Bilgiler'),
                    const SizedBox(height: 16),
                    _buildTextField(controller: _nameController, label: 'Ad Soyad', icon: Icons.person),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(controller: _ageController, label: 'Yaş', icon: Icons.cake, keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField<String>(
                            value: _selectedGender,
                            label: 'Cinsiyet',
                            icon: Icons.wc,
                            items: const [DropdownMenuItem(value: 'male', child: Text('Erkek')), DropdownMenuItem(value: 'female', child: Text('Kadın'))],
                            onChanged: (value) => setState(() => _selectedGender = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(controller: _heightController, label: 'Boy (cm)', icon: Icons.height, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(controller: _weightController, label: 'Kilo (kg)', icon: Icons.monitor_weight, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Hedefler'),
                    const SizedBox(height: 16),
                    _buildDropdownField<String>(
                      value: _selectedActivityLevel,
                      label: 'Aktivite Seviyesi',
                      icon: Icons.directions_run,
                      items: CalorieService.activityFactors.keys.map((key) => DropdownMenuItem<String>(value: key, child: Text(_getActivityLevelDisplayName(key)))).toList(),
                      onChanged: (value) => setState(() => _selectedActivityLevel = value),
                    ),
                    // Aktivite seviyesi açıklaması eklendi
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                      child: Text(
                        _getActivityLevelDescription(_selectedActivityLevel ?? 'sedentary'), // Varsayılan değer verildi
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField<int>(
                      value: _selectedWeeklyWorkoutDays,
                      label: 'Haftalık Antrenman Günü',
                      icon: Icons.calendar_today,
                      items: List.generate(8, (i) => DropdownMenuItem<int>(value: i, child: Text('$i gün'))),
                      onChanged: (value) => setState(() => _selectedWeeklyWorkoutDays = value),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField<String>(
                      value: _selectedGoal,
                      label: 'Hedef',
                      icon: Icons.flag,
                      items: const [
                        DropdownMenuItem(value: 'maintain', child: Text('Kilo Korumak')),
                        DropdownMenuItem(value: 'lose_weight', child: Text('Kilo Vermek')),
                        DropdownMenuItem(value: 'gain_muscle', child: Text('Kas Yapmak')),
                        DropdownMenuItem(value: 'lose_weight_gain_muscle', child: Text('Kilo Ver & Kas Yap')),
                      ],
                      onChanged: (value) => setState(() => _selectedGoal = value),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Vücut Analizi (Opsiyonel)'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(controller: _bodyFatController, label: 'Yağ Oranı (%)', icon: Icons.show_chart, keyboardType: const TextInputType.numberWithOptions(decimal: true), isOptional: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(controller: _muscleController, label: 'Kas Oranı (%)', icon: Icons.fitness_center, keyboardType: const TextInputType.numberWithOptions(decimal: true), isOptional: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(controller: _visceralFatController, label: 'İç Yağlanma', icon: Icons.local_fire_department, keyboardType: const TextInputType.numberWithOptions(decimal: true), isOptional: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(controller: _waterController, label: 'Su Oranı (%)', icon: Icons.water_drop, keyboardType: const TextInputType.numberWithOptions(decimal: true), isOptional: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(controller: _metabolicAgeController, label: 'Metabolizma Yaşı', icon: Icons.elderly, keyboardType: TextInputType.number, isOptional: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(controller: _boneController, label: 'Kemik Oranı (%)', icon: Icons.healing, keyboardType: const TextInputType.numberWithOptions(decimal: true), isOptional: true)),
                      ],
                    ),
                    const SizedBox(height: 24), // Yeni kart öncesi boşluk
                    // Vücut Kitle İndeksi (BMI) Kartı
                    _buildBMICard(context, user),
                    const SizedBox(height: 24), // Kart sonrası boşluk
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Yeni BMI Kartı
  Widget _buildBMICard(BuildContext context, UserModel user) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bmiCategory = CalorieService.getBMICategory(user.bmi);
    Color bmiColor;

    // BMI kategorisine göre renk belirleme
    switch (bmiCategory) {
      case 'Zayıf':
        bmiColor = Colors.blueAccent;
        break;
      case 'Normal':
        bmiColor = AppColors.primaryGreen;
        break;
      case 'Fazla Kilolu':
        bmiColor = Colors.orange;
        break;
      case 'Obez':
        bmiColor = AppColors.error;
        break;
      default:
        bmiColor = Colors.grey;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode ? AppColors.darkCard : AppColors.lightCard,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_weight_outlined, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 8),
                Text('Vücut Kitle İndeksi (BMI)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: Text(
                user.bmi.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: bmiColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                bmiCategory,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: bmiColor,
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                user.gender == 'male' ? 'Erkek' : 'Kadın', // Cinsiyet bilgisi
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  ImageProvider? _buildProfileImage(String? imagePath) {
    if (imagePath == null) return null;
    if (kIsWeb) {
      return NetworkImage(imagePath);
    } else {
      final file = File(imagePath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null;
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, bool isOptional = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Bu alan gerekli';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdownField<T>({required T? value, required String label, required IconData icon, required List<DropdownMenuItem<T>> items, required void Function(T?)? onChanged}) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      items: items,
      onChanged: onChanged,
      validator: (value) => value == null ? 'Lütfen bir seçim yapın' : null,
    );
  }

  String _getActivityLevelDisplayName(String key) {
    switch (key) {
      case 'sedentary': return 'Hareketsiz';
      case 'lightly_active': return 'Hafif Aktif';
      case 'moderately_active': return 'Orta Aktif';
      case 'very_active': return 'Çok Aktif';
      case 'extremely_active': return 'Aşırı Aktif';
      default: return 'Bilinmiyor';
    }
  }

  String _getActivityLevelDescription(String key) {
    switch (key) {
      case 'sedentary': return 'Çok az egzersiz veya hiç egzersiz yapmıyorsunuz.';
      case 'lightly_active': return 'Haftada 1-3 gün hafif egzersiz veya spor yapıyorsunuz.';
      case 'moderately_active': return 'Haftada 3-5 gün orta derecede egzersiz veya spor yapıyorsunuz.';
      case 'very_active': return 'Haftada 6-7 gün yoğun egzersiz veya spor yapıyorsunuz.';
      case 'extremely_active': return 'Günde 2 kez veya çok ağır fiziksel işler yapıyorsunuz.';
      default: return '';
    }
  }
}
