import 'package:photo_manager/photo_manager.dart';

class PhotoService {
  Future<List<AssetPathEntity>> getAlbums() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      throw Exception('Permission denied');
    }
    return await PhotoManager.getAssetPathList(type: RequestType.image);
  }

  Future<List<AssetEntity>> getPhotosFromAlbum(AssetPathEntity album) async {
    return await album.getAssetListRange(start: 0, end: 1000);
  }

  Future<List<AssetEntity>> getAllPhotos() async {
    final albums = await getAlbums();
    if (albums.isEmpty) return [];
    return await albums.first.getAssetListRange(start: 0, end: 1000);
  }
}
