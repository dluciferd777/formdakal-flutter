// lib/screens/photo_viewer_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class PhotoViewerScreen extends StatelessWidget {
  final String imagePath;
  final String heroTag; // Animasyonun hangi resmi hedefleyeceğini bilmesi için

  const PhotoViewerScreen({
    super.key,
    required this.imagePath,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea( // Burası eklendi
        child: GestureDetector(
          // Ekrana tıklandığında bir önceki sayfaya dön
          onTap: () {
            Navigator.pop(context);
          },
          child: Center(
            child: Hero(
              // Bu tag, listedeki resmin tag'i ile aynı olmalı
              tag: heroTag,
              child: InteractiveViewer( // Yakınlaştırma ve kaydırma için
                panEnabled: false, // Kaydırmayı devre dışı bırak
                minScale: 1.0,
                maxScale: 4.0,
                child: kIsWeb
                    ? Image.network(imagePath)
                    : Image.file(File(imagePath)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
