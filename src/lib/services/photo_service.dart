import 'package:photo_manager/photo_manager.dart';

class PhotoService {
  final FilterOptionGroup _filterOption = FilterOptionGroup(
    imageOption: const FilterOption(
      sizeConstraint: SizeConstraint(minWidth: 0, minHeight: 0),
    ),
  );

  // Cache the albums to avoid reloading
  List<AssetPathEntity>? _cachedAlbums;

  /// Checks if the app has permission to access photos
  Future<bool> hasPermission() async {
    final permissionState = await checkPermission();
    return permissionState == PermissionState.authorized || 
           permissionState == PermissionState.limited;
  }
  
  /// Check the current permission state
  Future<PermissionState> checkPermission() async {
    final PermissionState result = await PhotoManager.requestPermissionExtend();
    print('PhotoManager permission state: $result');
    return result;
  }

  /// Request permission to access photos
  Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result == PermissionState.authorized || result == PermissionState.limited;
  }

  /// Open settings to let the user change permissions
  Future<void> openSettings() async {
    await PhotoManager.openSetting();
  }

  /// Get all photos
  Future<List<AssetEntity>> getAllPhotos({int start = 0, int end = 20}) async {
    try {
      // Get the default album (all photos)
      final albums = await getAlbums();
      if (albums.isEmpty) {
        print('No albums found');
        return [];
      }
      
      final allPhotosAlbum = albums.first;
      return await getPhotosFromAlbum(allPhotosAlbum, start: start, end: end);
    } catch (e) {
      print('Error getting all photos: $e');
      return [];
    }
  }

  /// Load more photos (pagination)
  Future<List<AssetEntity>> loadMorePhotos(List<AssetEntity> existingPhotos, {int count = 20}) async {
    try {
      if (existingPhotos.isEmpty) {
        return await getAllPhotos(end: count);
      }
      
      final start = existingPhotos.length;
      final end = start + count;
      
      final newPhotos = await getAllPhotos(start: start, end: end);
      
      // Combine the lists and remove duplicates
      final allPhotos = [...existingPhotos];
      
      // Add only new photos that don't already exist in the list
      for (final photo in newPhotos) {
        if (!allPhotos.any((p) => p.id == photo.id)) {
          allPhotos.add(photo);
        }
      }
      
      return allPhotos;
    } catch (e) {
      print('Error loading more photos: $e');
      return existingPhotos;
    }
  }

  /// Get all albums
  Future<List<AssetPathEntity>> getAlbums() async {
    try {
      // Return cached albums if available
      if (_cachedAlbums != null) {
        return _cachedAlbums!;
      }
      
      final albums = await PhotoManager.getAssetPathList(
        onlyAll: false,
        type: RequestType.image,
        filterOption: _filterOption,
      );
      
      // Sort albums to ensure "All Photos" is first
      albums.sort((a, b) {
        if (a.isAll) return -1;
        if (b.isAll) return 1;
        return a.name.compareTo(b.name);
      });
      
      // Cache the albums
      _cachedAlbums = albums;
      
      return albums;
    } catch (e) {
      print('Error getting albums: $e');
      return [];
    }
  }

  /// Get photos from a specific album
  Future<List<AssetEntity>> getPhotosFromAlbum(
    AssetPathEntity album, {
    int start = 0,
    int end = 20,
  }) async {
    try {
      final assetList = await album.getAssetListRange(
        start: start,
        end: end,
      );
      
      // Sort by date (most recent first)
      assetList.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
      
      return assetList;
    } catch (e) {
      print('Error getting photos from album ${album.name}: $e');
      return [];
    }
  }
  
  /// Clear the album cache to force reload
  void clearCache() {
    _cachedAlbums = null;
  }
  
  /// Search photos by name
  Future<List<AssetEntity>> searchPhotosByName(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }
      
      // Get all photos first (limit to 500 for performance)
      final List<AssetEntity> allPhotos = await getAllPhotos(end: 500);
      
      // Filter photos that contain the query in their title/name
      final List<AssetEntity> matchingPhotos = allPhotos.where((photo) {
        final String? title = photo.title?.toLowerCase();
        final String? fileName = photo.relativePath?.split('/').last.toLowerCase();
        
        return (title != null && title.contains(query.toLowerCase())) ||
               (fileName != null && fileName.contains(query.toLowerCase()));
      }).toList();
      
      return matchingPhotos;
    } catch (e) {
      print('Error searching photos: $e');
      return [];
    }
  }
}
