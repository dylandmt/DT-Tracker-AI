import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/image_compressor.dart';

abstract class ProfileImageDataSource {
  Future<String> uploadImage({
    required String userId,
    required String filePath,
  });

  Future<void> deleteImage(String imageUrl);
}

class ProfileImageDataSourceImpl implements ProfileImageDataSource {
  final FirebaseStorage storage;
  final ImageCompressor imageCompressor;
  final Uuid _uuid = const Uuid();

  ProfileImageDataSourceImpl({
    required this.storage,
    required this.imageCompressor,
  });

  @override
  Future<String> uploadImage({
    required String userId,
    required String filePath,
  }) async {
    String? compressedPath;
    try {
      compressedPath = await imageCompressor.compressImage(
        filePath: filePath,
        quality: 70,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      final extension = _getFileExtension(filePath);
      final ref = storage.ref(
        'users/$userId/profile/images/${_uuid.v4()}.$extension',
      );
      final snapshot = await ref.putFile(
        File(compressedPath),
        SettableMetadata(contentType: _getContentType(extension)),
      );
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw ServerException(message: 'Failed to upload profile image: $e');
    } finally {
      if (compressedPath != null && compressedPath != filePath) {
        try {
          await File(compressedPath).delete();
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      await storage.refFromURL(imageUrl).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        throw ServerException(message: 'Failed to delete profile image: $e');
      }
    } catch (e) {
      throw ServerException(message: 'Failed to delete profile image: $e');
    }
  }

  String _getFileExtension(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extension)) {
      return extension == 'jpeg' ? 'jpg' : extension;
    }
    return 'jpg';
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
