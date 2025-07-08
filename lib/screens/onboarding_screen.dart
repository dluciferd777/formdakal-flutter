// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../utils/colors.dart';
import '../services/calorie_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedGender = 'male';
  String _selectedActivityLevel = 'moderately_active';
  String _selectedGoal = 'maintain';
  int _selectedWeeklyWorkoutDays = 3;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  
  Future<void> _completeOnboarding() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = UserModel(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        height: double.parse(_heightController.text.trim()),
        weight: double.parse(_weightController.text.trim()),
        gender: _selectedGender,
        activityLevel: _selectedActivityLevel,
        goal: _selectedGoal,
        weeklyWorkoutDays: _selectedWeeklyWorkoutDays,
      );
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.saveUser(user);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla oluşturuldu!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea( // Burası eklendi
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.fitness_center, color: Colors.white, size: 50),
                ),
                const SizedBox(height: 24),
                Text('Hoş Geldiniz!', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Başlamak için birkaç bilgiye ihtiyacımız var.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                _buildTextField(controller: _nameController, label: 'Ad Soyad', icon: Icons.person, validator: (v) => v!.isEmpty ? 'Bu alan gerekli' : null),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _ageController, label: 'Yaş', icon: Icons.cake, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Gerekli' : null)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdownField<String>(
                        value: _selectedGender,
                        label: 'Cinsiyet',
                        icon: Icons.wc,
                        items: const [ DropdownMenuItem(value: 'male', child: Text('Erkek')), DropdownMenuItem(value: 'female', child: Text('Kadın'))],
                        onChanged: (value) => setState(() => _selectedGender = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(controller: _heightController, label: 'Boy (cm)', icon: Icons.height, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Gerekli' : null)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(controller: _weightController, label: 'Kilo (kg)', icon: Icons.monitor_weight, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Gerekli' : null)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdownField<String>(
                  value: _selectedActivityLevel,
                  label: 'Aktivite Seviyesi',
                  icon: Icons.directions_run,
                  items: CalorieService.activityFactors.keys.map((key) => DropdownMenuItem<String>(value: key, child: Text(_getActivityLevelDisplayName(key)))).toList(),
                  onChanged: (value) => setState(() => _selectedActivityLevel = value!),
                ),
                // Aktivite seviyesi açıklaması eklendi
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                  child: Text(
                    _getActivityLevelDescription(_selectedActivityLevel),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDropdownField<int>(
                  value: _selectedWeeklyWorkoutDays,
                  label: 'Haftalık Antrenman Günü',
                  icon: Icons.calendar_today,
                  items: List.generate(8, (i) => DropdownMenuItem<int>(value: i, child: Text('$i gün'))),
                  onChanged: (value) => setState(() => _selectedWeeklyWorkoutDays = value!),
                ),
                const SizedBox(height: 16),
                _buildDropdownField<String>(
                  value: _selectedGoal,
                  label: 'Hedef',
                  icon: Icons.flag,
                  items: const [
                    DropdownMenuItem(value: 'maintain', child: Text('Kilo Korumak')),
                    DropdownMenuItem(value: 'lose_weight', child: Text('Kilo Vermek')), // 'Dropdown' düzeltildi
                    DropdownMenuItem(value: 'gain_muscle', child: Text('Kas Yapmak')),
                    DropdownMenuItem(value: 'lose_weight_gain_muscle', child: Text('Kilo Ver & Kas Yap')),
                  ],
                  onChanged: (value) => setState(() => _selectedGoal = value!),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _completeOnboarding,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    icon: _isLoading ? Container() : const Icon(Icons.check_circle_outline),
                    label: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Başla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({ required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2)),
      ),
    );
  }

  Widget _buildDropdownField<T>({ required T value, required String label, required IconData icon, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged}) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      items: items,
      onChanged: onChanged,
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
