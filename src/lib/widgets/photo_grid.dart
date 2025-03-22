import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/photo_service.dart';

class PhotoGrid extends StatefulWidget {
  const PhotoGrid({super.key});

  @override
  State<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<PhotoGrid> {
  final PhotoService _photoService = PhotoService();
  List<AssetEntity> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final photos = await _photoService.getAllPhotos();
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading photos: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final photo = _photos[index];
        return FutureBuilder<Uint8List?>(
          future: photo.thumbnailData,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return Image.memory(snapshot.data!, fit: BoxFit.cover);
          },
        );
      }, childCount: _photos.length),
    );
  }
}
