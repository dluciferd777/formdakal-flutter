// lib/screens/measurement_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/measurement_model.dart';
import '../providers/measurement_provider.dart';
import '../utils/colors.dart';

class MeasurementScreen extends StatelessWidget {
  const MeasurementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vücut Ölçülerim'),
      ),
      body: SafeArea(
        child: Consumer<MeasurementProvider>(
          builder: (context, provider, child) {
            if (provider.measurements.isEmpty) {
              return const Center(
                child: Text(
                  'Henüz ölçüm kaydı eklenmemiş.\nEklemek için + butonuna dokunun.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12), // Genel padding azaltıldı
              itemCount: provider.measurements.length,
              itemBuilder: (context, index) {
                final measurement = provider.measurements[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10), // Kartlar arası boşluk azaltıldı
                  child: Padding(
                    padding: const EdgeInsets.all(12.0), // Kart içi padding azaltıldı
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Tarih formatı düzeltildi ve yazı boyutu küçültüldü
                            Text(
                              DateFormat('yyyy MMMM EEEE, HH:mm', 'tr_TR').format(measurement.date),
                              style: Theme.of(context).textTheme.titleSmall?.copyWith( // titleSmall kullanıldı, daha küçük
                                    color: AppColors.primaryGreen,
                                    fontSize: 14, // Ekstra küçültme
                                  ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min, // Row'un minimum genişliği almasını sağlar
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20), // İkon boyutu küçültüldü
                                  onPressed: () => _showMeasurementDialog(context, measurement: measurement),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20), // İkon boyutu küçültüldü
                                  onPressed: () => _showDeleteConfirmation(context, measurement.id),
                                ),
                              ],
                            )
                          ],
                        ),
                        const Divider(height: 16), // Divider yüksekliği azaltıldı
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildMeasurementRow(context, 'Göğüs', measurement.chest),
                                  _buildMeasurementRow(context, 'Bel', measurement.waist),
                                  _buildMeasurementRow(context, 'Kalça', measurement.hips),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildMeasurementRow(context, 'Sağ Kol', measurement.rightArm),
                                  _buildMeasurementRow(context, 'Sol Kol', measurement.leftArm),
                                  _buildMeasurementRow(context, 'Sağ Bacak', measurement.rightThigh),
                                  _buildMeasurementRow(context, 'Sol Bacak', measurement.leftThigh),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMeasurementDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMeasurementRow(BuildContext context, String label, double? value) {
    if (value == null || value == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0), // Dikey padding azaltıldı
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600, fontSize: 12), // Yazı boyutu küçültüldü
          children: <TextSpan>[
            TextSpan(
              text: '${value.toStringAsFixed(1)} cm',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13), // Yazı boyutu küçültüldü
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: const Text('Bu ölçüm kaydını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
            onPressed: () {
              Provider.of<MeasurementProvider>(context, listen: false).deleteMeasurement(id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showMeasurementDialog(BuildContext context, {MeasurementModel? measurement}) {
    final isEditing = measurement != null;
    final formKey = GlobalKey<FormState>();
    
    final controllers = {
      'chest': TextEditingController(text: measurement?.chest?.toString() ?? ''),
      'waist': TextEditingController(text: measurement?.waist?.toString() ?? ''),
      'hips': TextEditingController(text: measurement?.hips?.toString() ?? ''),
      'leftArm': TextEditingController(text: measurement?.leftArm?.toString() ?? ''),
      'rightArm': TextEditingController(text: measurement?.rightArm?.toString() ?? ''),
      'leftThigh': TextEditingController(text: measurement?.leftThigh?.toString() ?? ''),
      'rightThigh': TextEditingController(text: measurement?.rightThigh?.toString() ?? ''),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEditing ? 'Ölçümü Düzenle' : 'Yeni Ölçüm Ekle',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  ...controllers.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextFormField(
                        controller: entry.value,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: '${_getLabel(entry.key)} (cm)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final newMeasurement = MeasurementModel(
                          id: measurement?.id,
                          date: measurement?.date ?? DateTime.now(),
                          chest: double.tryParse(controllers['chest']!.text),
                          waist: double.tryParse(controllers['waist']!.text),
                          hips: double.tryParse(controllers['hips']!.text),
                          leftArm: double.tryParse(controllers['leftArm']!.text),
                          rightArm: double.tryParse(controllers['rightArm']!.text),
                          leftThigh: double.tryParse(controllers['leftThigh']!.text),
                          rightThigh: double.tryParse(controllers['rightThigh']!.text),
                        );

                        final provider = Provider.of<MeasurementProvider>(context, listen: false);
                        if (isEditing) {
                          provider.updateMeasurement(newMeasurement);
                        } else {
                          provider.addMeasurement(newMeasurement);
                        }
                        Navigator.of(ctx).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
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
  }

  String _getLabel(String key) {
    switch (key) {
      case 'chest': return 'Göğüs';
      case 'waist': return 'Bel';
      case 'hips': return 'Kalça';
      case 'leftArm': return 'Sol Kol';
      case 'rightArm': return 'Sağ Kol';
      case 'leftThigh': return 'Sol Bacak';
      case 'rightThigh': return 'Sağ Bacak';
      default: return '';
    }
  }
}
