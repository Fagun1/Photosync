import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/photo_service.dart';
import '../screens/home_screen.dart';

class PhotoGrid extends StatefulWidget {
  final PhotoService? photoService;
  
  const PhotoGrid({super.key, this.photoService});

  @override
  State<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<PhotoGrid> {
  final List<AssetEntity> _photos = [];
  bool _isLoading = true;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final int _pageSize = 30;
  late final PhotoService _photoService;
  
  // We don't need a ScrollController for a SliverGrid as it's managed by the parent CustomScrollView
  // The issue is likely caused by trying to attach this controller to a sliver

  @override
  void initState() {
    super.initState();
    _photoService = widget.photoService ?? PhotoService();
    _checkPermissionAndLoadPhotos();
  }

  Future<void> _checkPermissionAndLoadPhotos() async {
    try {
      final hasPermission = await _photoService.hasPermission();
      
      if (!hasPermission) {
        // Try to request permission
        final granted = await _photoService.requestPermission();
        if (!granted && mounted) {
          setState(() {
            _isLoading = false;
          });
          _showPermissionDeniedError();
          return;
        }
      }
      
      await _loadPhotos();
    } catch (e) {
      print('Error checking permission: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPermissionDeniedError() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Permission to access photos is required'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () {
            _photoService.openSettings();
          },
        ),
      ),
    );
  }

  Future<void> _loadPhotos() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }
      
      final photos = await _photoService.getAllPhotos(end: _pageSize);
      print('Loaded ${photos.length} photos');
      
      if (mounted) {
        setState(() {
          _photos.addAll(photos);
          _isLoading = false;
          _hasMore = photos.length >= _pageSize;
        });
      }
    } catch (e) {
      print('Error loading photos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading photos: $e')),
        );
      }
    }
  }

  Future<void> _loadMorePhotos() async {
    if (_isLoadingMore || !_hasMore) return;
    
    try {
      if (mounted) {
        setState(() {
          _isLoadingMore = true;
        });
      }
      
      final morePhotos = await _photoService.loadMorePhotos(_photos, count: _pageSize);
      final newPhotosCount = morePhotos.length - _photos.length;
      print('Loaded $newPhotosCount more photos');
      
      if (mounted) {
        setState(() {
          _photos.clear();
          _photos.addAll(morePhotos);
          _isLoadingMore = false;
          _hasMore = newPhotosCount > 0;
        });
      }
    } catch (e) {
      print('Error loading more photos: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
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

    if (_photos.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No photos found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPermissionAndLoadPhotos,
                child: const Text('Retry Loading Photos'),
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Load more photos when reaching near the end, but use post-frame callback
          // to avoid setState during build
          if (index >= _photos.length - 5 && !_isLoadingMore && _hasMore) {
            // Use a post-frame callback to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadMorePhotos();
            });
          }
          
          if (index >= _photos.length) {
            return const SizedBox.shrink();
          }
          
          final photo = _photos[index];
          return GestureDetector(
            onTap: () {
              // Navigate to full screen view
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenPhotoView(
                    photo: photo,
                    allPhotos: _photos,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Hero(
              tag: photo.id,
              child: FutureBuilder<Uint8List?>(
                future: photo.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  }
                  
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
        childCount: _photos.length,
      ),
    );
  }
}
