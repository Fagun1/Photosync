import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../widgets/top_app_bar.dart';
import '../services/photo_service.dart';
import '../screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final PhotoService photoService;

  const SearchScreen({
    super.key, 
    required this.onThemeToggle,
    required this.photoService,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AssetEntity> _searchResults = [];
  bool _isSearching = false;
  List<String> _recentSearches = [];
  bool _hasPermission = false;
  static const String _recentSearchesKey = 'recent_searches';

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _loadRecentSearches();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _checkPermission() async {
    final hasPermission = await widget.photoService.hasPermission();
    if (mounted) {
      setState(() {
        _hasPermission = hasPermission;
      });
    }
  }
  
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_recentSearchesKey);
      
      if (searches != null && mounted) {
        setState(() {
          _recentSearches = searches;
        });
      }
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }
  
  Future<void> _saveRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, _recentSearches);
    } catch (e) {
      print('Error saving recent searches: $e');
    }
  }
  
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final results = await widget.photoService.searchPhotosByName(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          
          // Add to recent searches if not already there
          if (query.isNotEmpty && !_recentSearches.contains(query)) {
            _recentSearches.insert(0, query);
            // Limit to 5 recent searches
            if (_recentSearches.length > 5) {
              _recentSearches = _recentSearches.sublist(0, 5);
            }
            _saveRecentSearches(); // Save to shared preferences
          }
        });
      }
    } catch (e) {
      print('Error performing search: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopAppBar(title: 'Search', onThemeToggle: widget.onThemeToggle),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search photos...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                ),
                onChanged: (value) {
                  // Don't search on every character for performance reasons
                  if (value.length >= 3 || value.isEmpty) {
                    _performSearch(value);
                  }
                },
                onSubmitted: _performSearch,
              ),
            ),
          ),
          
          if (_isSearching)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_searchController.text.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Searches',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (_recentSearches.isEmpty)
                      const Center(child: Text('No recent searches'))
                    else
                      Column(
                        children: _recentSearches.map((search) => 
                          ListTile(
                            leading: const Icon(Icons.history),
                            title: Text(search),
                            onTap: () {
                              _searchController.text = search;
                              _performSearch(search);
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.north_west),
                              onPressed: () {
                                _searchController.text = search;
                                _performSearch(search);
                              },
                            ),
                          )
                        ).toList(),
                      ),
                  ],
                ),
              ),
            )
          else if (!_hasPermission)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.no_photography, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Permission required to search photos'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final granted = await widget.photoService.requestPermission();
                        if (mounted) {
                          setState(() {
                            _hasPermission = granted;
                          });
                          if (granted) {
                            _performSearch(_searchController.text);
                          }
                        }
                      },
                      child: const Text('Grant Permission'),
                    ),
                  ],
                ),
              ),
            )
          else if (_searchResults.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No photos found')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(8.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final photo = _searchResults[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenPhotoView(
                              photo: photo,
                              allPhotos: _searchResults,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'search_${photo.id}',
                        child: FutureBuilder<Uint8List?>(
                          future: photo.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            }
                            
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                                if (photo.title != null)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        photo.title!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                  childCount: _searchResults.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
