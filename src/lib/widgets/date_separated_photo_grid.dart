import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import '../services/photo_service.dart';
import '../screens/home_screen.dart';

class DateSeparatedPhotoGrid extends StatefulWidget {
  final PhotoService photoService;

  const DateSeparatedPhotoGrid({
    Key? key,
    required this.photoService,
  }) : super(key: key);

  @override
  State<DateSeparatedPhotoGrid> createState() => _DateSeparatedPhotoGridState();
}

class _DateSeparatedPhotoGridState extends State<DateSeparatedPhotoGrid> {
  final List<AssetEntity> _photos = [];
  final int _pageSize = 30;
  bool _isLoading = true;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  Map<String, List<AssetEntity>> _photosByDate = {};
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_hasMore && 
        !_isLoading && 
        !_isLoadingMore && 
        _scrollController.position.pixels > 
        _scrollController.position.maxScrollExtent - 500) {
      _loadMorePhotos();
    }
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    if (!mounted) return;
    
    try {
      final hasPermission = await widget.photoService.hasPermission();
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final photos = await widget.photoService.getAllPhotos(end: _pageSize);
      
      if (!mounted) return;
      
      setState(() {
        _photos.clear();
        _photos.addAll(photos);
        _isLoading = false;
        _hasMore = photos.length >= _pageSize;
        _photosByDate = _groupPhotosByDate(photos);
      });
    } catch (e) {
      print('Error loading photos: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePhotos() async {
    if (_isLoading || _isLoadingMore || !_hasMore || !mounted) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final newPhotos = await widget.photoService.loadMorePhotos(_photos, count: _pageSize);
      
      if (!mounted) return;
      
      setState(() {
        // Check if we got new photos
        final hasNewPhotos = newPhotos.length > _photos.length;
        
        if (hasNewPhotos) {
          _photos.clear();
          _photos.addAll(newPhotos);
          _photosByDate = _groupPhotosByDate(newPhotos);
        }
        
        _hasMore = hasNewPhotos && newPhotos.length >= _photos.length + (_pageSize / 2).floor();
        _isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading more photos: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Map<String, List<AssetEntity>> _groupPhotosByDate(List<AssetEntity> photos) {
    final Map<String, List<AssetEntity>> result = {};
    
    for (final photo in photos) {
      final dateKey = _formatDate(photo.createDateTime);
      if (!result.containsKey(dateKey)) {
        result[dateKey] = [];
      }
      result[dateKey]!.add(photo);
    }
    
    return result;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final photoDate = DateTime(date.year, date.month, date.day);

    if (photoDate == today) {
      return 'Today';
    } else if (photoDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(photoDate).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name (e.g., Monday)
    } else if (date.year == now.year) {
      return DateFormat('MMMM d').format(date); // Month and day
    } else {
      return DateFormat('MMMM d, y').format(date); // Month, day and year
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final permissionFuture = widget.photoService.hasPermission();
    
    return FutureBuilder<bool>(
      future: permissionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final hasPermission = snapshot.data ?? false;
        
        if (!hasPermission) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Permission denied',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final granted = await widget.photoService.requestPermission();
                    if (granted && mounted) {
                      _loadPhotos();
                    }
                  },
                  child: const Text('Grant Permission'),
                ),
              ],
            ),
          );
        }

        if (_photos.isEmpty) {
          return const Center(
            child: Text('No photos found'),
          );
        }

        // Create list of category widgets
        final List<Widget> dateCategories = [];
        
        // Sort dates to ensure newest are first
        final sortedDates = _photosByDate.keys.toList()
          ..sort((a, b) {
            // Put "Today" and "Yesterday" at the top
            if (a == 'Today') return -1;
            if (b == 'Today') return 1;
            if (a == 'Yesterday') return -1;
            if (b == 'Yesterday') return 1;
            
            // For other dates, try to compare by recency
            final dateA = _parseDate(a);
            final dateB = _parseDate(b);
            
            if (dateA != null && dateB != null) {
              return dateB.compareTo(dateA); // Most recent first
            }
            
            // Fallback to string comparison
            return b.compareTo(a);
          });
        
        for (final dateKey in sortedDates) {
          final photosInCategory = _photosByDate[dateKey]!;
          
          dateCategories.add(
            Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateKey,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: photosInCategory.length,
                    itemBuilder: (context, index) {
                      final photo = photosInCategory[index];
                      
                      // Check if we're approaching the end of the content
                      // and need to load more photos
                      if (dateKey == sortedDates.last && 
                          index == photosInCategory.length - 1 && 
                          _hasMore && 
                          !_isLoadingMore) {
                        _loadMorePhotos();
                      }
                      
                      return GestureDetector(
                        onTap: () {
                          // Find the global index of this photo
                          final globalIndex = _photos.indexOf(photo);
                          if (globalIndex != -1) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FullScreenPhotoView(
                                  photos: _photos,
                                  initialIndex: globalIndex,
                                ),
                              ),
                            );
                          }
                        },
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: FutureBuilder<Uint8List?>(
                            future: photo.thumbnailData,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                );
                              } else {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }
        
        return SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              ...dateCategories,
              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  DateTime? _parseDate(String formattedDate) {
    try {
      final now = DateTime.now();
      if (formattedDate == 'Today') {
        return DateTime(now.year, now.month, now.day);
      } else if (formattedDate == 'Yesterday') {
        return DateTime(now.year, now.month, now.day - 1);
      }
      
      // Try to parse other date formats
      for (final format in [
        'EEEE', // Day name
        'MMMM d', // Month and day
        'MMMM d, y', // Month, day and year
      ]) {
        try {
          final date = DateFormat(format).parse(formattedDate);
          // If it's a day name format, adjust to this week
          if (format == 'EEEE') {
            final weekday = date.weekday;
            final today = now.weekday;
            int diff = weekday - today;
            if (diff > 0) diff -= 7; // Adjust to previous week if needed
            return DateTime(now.year, now.month, now.day + diff);
          }
          
          // For other formats, if year is missing, use current year
          if (format == 'MMMM d') {
            return DateTime(now.year, date.month, date.day);
          }
          
          return date;
        } catch (_) {
          // Try next format
        }
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return null;
  }
}

class FullScreenPhotoView extends StatefulWidget {
  final List<AssetEntity> photos;
  final int initialIndex;

  const FullScreenPhotoView({
    Key? key,
    required this.photos,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullScreenPhotoView> createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends State<FullScreenPhotoView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showPhotoDetails(context, widget.photos[_currentIndex]),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Implement share functionality
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: FutureBuilder<Uint8List?>(
                future: photo.originBytes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  }
                  
                  if (snapshot.hasData) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 50,
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                        size: 50,
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPhotoDetails(BuildContext context, AssetEntity photo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Photo Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Date', DateFormat('MMM d, y HH:mm').format(photo.createDateTime)),
              _buildDetailRow('Resolution', '${photo.width} × ${photo.height}'),
              _buildDetailRow('Type', photo.mimeType ?? 'Unknown'),
              
              FutureBuilder<Uint8List?>(
                future: photo.originBytes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildDetailRow('Size', 'Calculating...');
                  }
                  
                  if (snapshot.hasData && snapshot.data != null) {
                    final bytes = snapshot.data!.length;
                    final kb = bytes / 1024;
                    final mb = kb / 1024;
                    
                    return _buildDetailRow(
                      'Size', 
                      mb >= 1 
                          ? '${mb.toStringAsFixed(2)} MB' 
                          : '${kb.toStringAsFixed(2)} KB'
                    );
                  }
                  
                  return _buildDetailRow('Size', 'Unknown');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
} 