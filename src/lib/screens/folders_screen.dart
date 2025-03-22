import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/top_app_bar.dart';
import '../services/photo_service.dart';
import 'package:photo_manager/photo_manager.dart';
import '../screens/home_screen.dart';

class FoldersScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final PhotoService photoService;

  const FoldersScreen({
    super.key, 
    required this.onThemeToggle,
    required this.photoService,
  });

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<AssetPathEntity> _albums = [];
  bool _isLoading = true;
  final Map<String, Uint8List?> _albumThumbnails = {};

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    try {
      // First check permission
      final permission = await widget.photoService.checkPermission();
      if (!permission.isAuth && permission != PermissionState.limited) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission required to view albums')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get albums
      final albums = await widget.photoService.getAlbums();
      
      if (mounted) {
        setState(() {
          _albums = albums;
          _isLoading = false;
        });
      }
      
      // Load thumbnails for each album
      _loadAlbumThumbnails();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading albums: $e')),
        );
      }
    }
  }

  Future<void> _loadAlbumThumbnails() async {
    for (final album in _albums) {
      try {
        // Get the first photo in the album to use as thumbnail
        final photos = await album.getAssetListRange(start: 0, end: 1);
        if (photos.isNotEmpty) {
          final thumbnail = await photos.first.thumbnailDataWithSize(
            const ThumbnailSize(200, 200),
          );
          
          if (mounted) {
            setState(() {
              _albumThumbnails[album.id] = thumbnail;
            });
          }
        }
      } catch (e) {
        // Skip this album's thumbnail if there's an error
        print('Error loading thumbnail for album ${album.name}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopAppBar(title: 'Library', onThemeToggle: widget.onThemeToggle),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Albums section with "View all" link
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Albums',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AllAlbumsScreen(
                                      photoService: widget.photoService,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('View all'),
                            ),
                          ],
                        ),
                      ),
                      _albums.isEmpty
                          ? const SizedBox(
                              height: 180,
                              child: Center(child: Text('No albums found')),
                            )
                          : SizedBox(
                              height: 180,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _albums.length,
                                itemBuilder: (context, index) {
                                  final album = _albums[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AlbumViewScreen(
                                              album: album,
                                              photoService: widget.photoService,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: SizedBox(
                                              width: 160,
                                              height: 120,
                                              child: _albumThumbnails[album.id] != null
                                                  ? Image.memory(
                                                      _albumThumbnails[album.id]!,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.photo_album,
                                                        size: 50,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            album.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          FutureBuilder<int>(
                                            future: album.assetCountAsync,
                                            builder: (context, snapshot) {
                                              return Text(
                                                '${snapshot.data ?? 0} items',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                      
                      // Memories section (placeholder)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Memories',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () {
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
                          itemCount: 5, // Placeholder memories
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
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
                            );
                          },
                        ),
                      ),
                      
                      // Some extra spacing at the bottom
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
