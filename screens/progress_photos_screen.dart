// lib/screens/progress_photos_screen.dart - MODERN GALERİ GÖRÜNÜM
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/progress_photo_model.dart';
import '../providers/progress_photo_provider.dart';
import '../utils/colors.dart';
import 'photo_viewer_screen.dart';

class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _addPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final newPhoto = ProgressPhotoModel(
          imagePath: image.path,
          date: DateTime.now(),
        );
        await Provider.of<ProgressPhotoProvider>(context, listen: false)
            .addPhoto(newPhoto);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim seçilemedi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fotoğrafı Sil'),
        content: const Text('Bu ilerleme fotoğrafını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
            onPressed: () {
              Provider.of<ProgressPhotoProvider>(context, listen: false).deletePhoto(id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('İlerleme Fotoğraflarım'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _addPhoto,
            tooltip: 'Fotoğraf Ekle',
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ProgressPhotoProvider>(
          builder: (context, provider, child) {
            if (provider.photos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz fotoğraf eklenmemiş',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'İlerlemenizi kaydetmeye başlayın!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Fotoğrafları aya göre grupla
            final groupedPhotos = groupBy(
              provider.photos,
              (ProgressPhotoModel photo) => DateFormat('yyyy MMMM', 'tr_TR').format(photo.date),
            );

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedPhotos.length,
              itemBuilder: (context, index) {
                final month = groupedPhotos.keys.elementAt(index);
                final photosInMonth = groupedPhotos[month]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ay başlığı
                    Padding(
                      padding: EdgeInsets.only(bottom: 16, top: index == 0 ? 0 : 24),
                      child: Text(
                        month,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Modern grid layout
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 3 sütun - telefon galerisi gibi
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                        childAspectRatio: 1, // Kare fotoğraflar
                      ),
                      itemCount: photosInMonth.length,
                      itemBuilder: (context, photoIndex) {
                        final photo = photosInMonth[photoIndex];
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PhotoViewerScreen(
                                  imagePath: photo.imagePath,
                                  heroTag: photo.id,
                                ),
                              ),
                            );
                          },
                          onLongPress: () => _showDeleteConfirmation(context, photo.id),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 0.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Fotoğraf
                                  Hero(
                                    tag: photo.id,
                                    child: kIsWeb
                                        ? Image.network(
                                            photo.imagePath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey,
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white54,
                                                ),
                                              );
                                            },
                                          )
                                        : Image.file(
                                            File(photo.imagePath),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey,
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white54,
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  
                                  // Tarih overlay (sağ alt köşe)
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        DateFormat('d').format(photo.date),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Gradient overlay (altta)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 30,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.6),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPhoto,
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }
}