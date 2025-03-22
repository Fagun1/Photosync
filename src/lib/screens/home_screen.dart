import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/photo_grid.dart';
import '../widgets/top_app_bar.dart';
import '../widgets/date_separated_photo_grid.dart';
import 'folders_screen.dart';
import 'search_screen.dart';
import '../services/photo_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final PhotoService photoService;

  const HomeScreen({
    super.key, 
    required this.onThemeToggle,
    required this.photoService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  bool _isPermissionHandled = false;
  PermissionState? _permissionState;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _checkAndRequestPermission();
  }

  Future<void> _checkAndRequestPermission() async {
    try {
      // Check permission status
      final permissionState = await widget.photoService.checkPermission();
      setState(() {
        _permissionState = permissionState;
        _isPermissionHandled = true;
      });
      
      // If not authorized, request permission
      if (!permissionState.isAuth && permissionState != PermissionState.limited) {
        await _requestPermission();
      }
    } catch (e) {
      print('Error checking permission: $e');
    }
  }

  void _initializeScreens() {
    _screens = [
      _HomeContent(
        onThemeToggle: widget.onThemeToggle,
        photoService: widget.photoService,
        onRequestPermission: _requestPermission,
      ),
      FoldersScreen(
        onThemeToggle: widget.onThemeToggle,
        photoService: widget.photoService,
      ),
      SearchScreen(
        onThemeToggle: widget.onThemeToggle,
        photoService: widget.photoService,
      ),
    ];
  }

  Future<void> _requestPermission() async {
    try {
      final isGranted = await widget.photoService.requestPermission();
      final newState = await widget.photoService.checkPermission();
      setState(() {
        _permissionState = newState;
      });
      
      if (!isGranted) {
        _showPermissionDialog();
      }
    } catch (e) {
      print('Error requesting permission: $e');
    }
  }

  void _showPermissionDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'PhotoSync needs access to your photos to display them. '
          'Please grant permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.photoService.openSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Folders',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final PhotoService photoService;
  final VoidCallback onRequestPermission;

  const _HomeContent({
    required this.onThemeToggle,
    required this.photoService,
    required this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopAppBar(title: 'PhotoSync', onThemeToggle: onThemeToggle),
      body: FutureBuilder<bool>(
        future: photoService.hasPermission(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final hasPermission = snapshot.data ?? false;
          
          if (!hasPermission) {
            return _buildPermissionRequest(context);
          }
          
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Albums',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to Albums page instead of folders tab
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllAlbumsScreen(
                                    photoService: photoService,
                                  ),
                                ),
                              );
                            },
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 180,
                      child: FutureBuilder<List<AssetPathEntity>>(
                        future: photoService.getAlbums(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('No albums found'));
                          }
                          
                          final albums = snapshot.data!;
                          
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: albums.length,
                            itemBuilder: (context, index) {
                              final album = albums[index];
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AlbumViewScreen(
                                          album: album,
                                          photoService: photoService,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FutureBuilder<List<AssetEntity>>(
                                        future: photoService.getPhotosFromAlbum(album, start: 0, end: 1),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                            return Container(
                                              width: 160,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: Icon(Icons.photo_album, color: Colors.grey),
                                              ),
                                            );
                                          }
                                          
                                          final photo = snapshot.data!.first;
                                          
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: FutureBuilder<Uint8List?>(
                                              future: photo.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData) {
                                                  return Container(
                                                    width: 160,
                                                    height: 120,
                                                    color: Colors.grey[300],
                                                    child: const Center(child: CircularProgressIndicator()),
                                                  );
                                                }
                                                
                                                return Image.memory(
                                                  snapshot.data!,
                                                  width: 160,
                                                  height: 120,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      width: 160,
                                                      height: 120,
                                                      color: Colors.grey[300],
                                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: 160,
                                        child: Text(
                                          album.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      FutureBuilder<int>(
                                        future: album.assetCountAsync,
                                        builder: (context, snapshot) {
                                          final count = snapshot.data ?? 0;
                                          return Text(
                                            '$count items',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Memories',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to Memories page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MemoriesScreen(),
                                ),
                              );
                            },
                            child: const Text('View all'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 5, // Limited number of memories for now
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () {
                                // Will be implemented when backend is ready
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 160,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.favorite_border,
                                        color: Colors.grey[600],
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Memory ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${DateTime.now().year - index} Collection',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'All Photos',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              SliverAppBar(
                title: const Text('All Photos'),
                floating: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      // Search functionality to be implemented
                    },
                  ),
                ],
              ),
              PhotoGrid(photoService: photoService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermissionRequest(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          Text(
            'Photo Access Required',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'PhotoSync needs access to your photos to display them in the app.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onRequestPermission,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text('Grant Access'),
            ),
          ),
        ],
      ),
    );
  }
}

// Add new screens for Album View and Full Screen Photo
class AlbumViewScreen extends StatelessWidget {
  final AssetPathEntity album;
  final PhotoService photoService;

  const AlbumViewScreen({
    super.key,
    required this.album,
    required this.photoService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(album.name),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: FutureBuilder<List<AssetEntity>>(
              future: photoService.getPhotosFromAlbum(album, end: 500),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No photos in this album')),
                  );
                }
                
                final photos = snapshot.data!;
                
                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final photo = photos[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenPhotoView(
                                photo: photo,
                                allPhotos: photos,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: 'album_${album.id}_photo_${photo.id}',
                          child: FutureBuilder<Uint8List?>(
                            future: photo.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(child: CircularProgressIndicator()),
                                );
                              }
                              
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
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
                    childCount: photos.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenPhotoView extends StatefulWidget {
  final AssetEntity photo;
  final List<AssetEntity>? allPhotos;
  final int? initialIndex;
  
  const FullScreenPhotoView({
    super.key,
    required this.photo,
    this.allPhotos,
    this.initialIndex,
  });
  
  @override
  State<FullScreenPhotoView> createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends State<FullScreenPhotoView> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<String, Future<Uint8List?>> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
    
    // Pre-cache adjacent images for smoother experience
    _preloadAdjacentImages();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  Future<void> _preloadAdjacentImages() async {
    if (widget.allPhotos == null || widget.allPhotos!.isEmpty) return;
    
    final photos = widget.allPhotos!;
    final currentIndex = _currentIndex;
    
    // Cache current photo
    _getCachedImage(photos[currentIndex]);
    
    // Cache next photo if available
    if (currentIndex + 1 < photos.length) {
      _getCachedImage(photos[currentIndex + 1]);
    }
    
    // Cache previous photo if available
    if (currentIndex - 1 >= 0) {
      _getCachedImage(photos[currentIndex - 1]);
    }
  }
  
  Future<Uint8List?> _getCachedImage(AssetEntity photo) {
    if (!_imageCache.containsKey(photo.id)) {
      _imageCache[photo.id] = photo.originBytes;
    }
    return _imageCache[photo.id]!;
  }
  
  @override
  Widget build(BuildContext context) {
    // Single photo view if there are no other photos to slide through
    if (widget.allPhotos == null || widget.allPhotos!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildAppBar(widget.photo),
        body: _buildPhotoView(widget.photo),
      );
    }
    
    // Multi-photo view with sliding capabilities
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(widget.allPhotos![_currentIndex]),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.allPhotos!.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            // Preload next set of images when page changes
            _preloadAdjacentImages();
          });
        },
        itemBuilder: (context, index) {
          final photo = widget.allPhotos![index];
          return _buildPhotoView(photo);
        },
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(AssetEntity photo) {
    final DateTime dateTime = photo.createDateTime;
    final String formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.5),
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        formattedDate,
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            _sharePhoto(photo);
          },
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            _showPhotoDetails(photo);
          },
        ),
      ],
    );
  }
  
  Widget _buildPhotoView(AssetEntity photo) {
    return Hero(
      tag: photo.id,
      child: FutureBuilder<Uint8List?>(
        future: _getCachedImage(photo),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            return Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 64),
              ),
            );
          }
          
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _showPhotoDetails(AssetEntity photo) {
    final width = photo.width;
    final height = photo.height;
    final date = photo.createDateTime;
    final formattedDate = DateFormat('MMMM d, yyyy - HH:mm').format(date);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
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
              _detailRow('Date', formattedDate),
              _detailRow('Resolution', '$width × $height'),
              FutureBuilder<Uint8List?>(
                future: photo.originBytes,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final fileSizeInMB = (snapshot.data!.length / (1024 * 1024)).toStringAsFixed(2);
                    return _detailRow('Size', '$fileSizeInMB MB');
                  }
                  return const SizedBox.shrink();
                },
              ),
              _detailRow('Type', photo.mimeType ?? 'Unknown'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePhoto(AssetEntity photo) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing to share...')),
      );
      
      final file = await photo.file;
      if (file != null) {
        try {
          // Use share_plus to share the file
          await Share.shareXFiles(
            [XFile(file.path)],
            text: 'Shared from PhotoSync',
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error sharing: $e')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to share this photo')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error preparing share: $e')),
        );
      }
    }
  }
}

// Add AllAlbumsScreen for viewing all albums
class AllAlbumsScreen extends StatelessWidget {
  final PhotoService photoService;

  const AllAlbumsScreen({
    super.key,
    required this.photoService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Albums'),
      ),
      body: FutureBuilder<List<AssetPathEntity>>(
        future: photoService.getAlbums(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No albums found'));
          }
          
          final albums = snapshot.data!;
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumViewScreen(
                        album: album,
                        photoService: photoService,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FutureBuilder<List<AssetEntity>>(
                        future: photoService.getPhotosFromAlbum(album, start: 0, end: 1),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(Icons.photo_album, color: Colors.grey),
                              ),
                            );
                          }
                          
                          final photo = snapshot.data!.first;
                          
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FutureBuilder<Uint8List?>(
                              future: photo.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                }
                                
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      album.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    FutureBuilder<int>(
                      future: album.assetCountAsync,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Text(
                          '$count items',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Add MemoriesScreen (placeholder for now)
class MemoriesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memories'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Memories Coming Soon',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'We\'re working on this feature. Memories will be available soon.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

