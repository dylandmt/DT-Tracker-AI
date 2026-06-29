import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/image_compressor.dart';

/// Abstract interface for vehicle image data source
abstract class VehicleImageDataSource {
  /// Upload an image to Firebase Storage
  ///
  /// Path: vehicles/{userId}/{vehicleId}/{uuid}.{ext}
  /// Returns the download URL
  Future<String> uploadImage({
    required String userId,
    required String vehicleId,
    required String filePath,
  });

  /// Delete an image from Firebase Storage
  Future<void> deleteImage(String imageUrl);
}

/// Implementation of [VehicleImageDataSource] using Firebase Storage
class VehicleImageDataSourceImpl implements VehicleImageDataSource {
  final FirebaseStorage storage;
  final ImageCompressor imageCompressor;
  final Uuid _uuid = const Uuid();

  VehicleImageDataSourceImpl({
    required this.storage,
    required this.imageCompressor,
  });

  @override
  Future<String> uploadImage({
    required String userId,
    required String vehicleId,
    required String filePath,
  }) async {
    try {
      // Compress the image first
      final compressedPath = await imageCompressor.compressImage(
        filePath: filePath,
        quality: 70,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      // Get file extension
      final extension = _getFileExtension(filePath);

      // Generate unique filename
      final filename = '${_uuid.v4()}.$extension';

      // Create storage reference
      final ref = storage.ref('vehicles/$userId/$vehicleId/$filename');

      // Upload file
      final file = File(compressedPath);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'vehicleId': vehicleId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up compressed file if it's different from original
      if (compressedPath != filePath) {
        try {
          await File(compressedPath).delete();
        } catch (_) {
          // Ignore cleanup errors
        }
      }

      return downloadUrl;
    } catch (e) {
      throw ServerException(message: 'Failed to upload image: $e');
    }
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Get reference from URL
      final ref = storage.refFromURL(imageUrl);

      // Delete file
      await ref.delete();
    } catch (e) {
      // If file doesn't exist, consider it a success
      if (e is FirebaseException && e.code == 'object-not-found') {
        return;
      }
      throw ServerException(message: 'Failed to delete image: $e');
    }
  }

  /// Get file extension from path
  String _getFileExtension(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extension)) {
      return extension == 'jpeg' ? 'jpg' : extension;
    }
    return 'jpg';
  }

  /// Get content type from extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
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
