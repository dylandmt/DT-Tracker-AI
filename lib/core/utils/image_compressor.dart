import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

/// Abstract interface for image compression
abstract class ImageCompressor {
  /// Compress an image file
  ///
  /// [filePath] - Path to the original image file
  /// [quality] - Compression quality (0-100, default 70)
  /// [maxWidth] - Maximum width (default 1080)
  /// [maxHeight] - Maximum height (default 1080)
  ///
  /// Returns the path to the compressed image file in temp directory
  Future<String> compressImage({
    required String filePath,
    int quality = 70,
    int maxWidth = 1080,
    int maxHeight = 1080,
  });

  /// Compress multiple images
  ///
  /// Returns a list of paths to compressed image files
  Future<List<String>> compressImages({
    required List<String> filePaths,
    int quality = 70,
    int maxWidth = 1080,
    int maxHeight = 1080,
  });

  /// Compress image bytes directly
  ///
  /// Returns compressed image bytes
  Future<Uint8List?> compressBytes({
    required Uint8List bytes,
    int quality = 70,
    int maxWidth = 1080,
    int maxHeight = 1080,
  });

  /// Get a compressed version of the image file as bytes
  ///
  /// Returns compressed image bytes
  Future<Uint8List?> compressFileToBytes({
    required String filePath,
    int quality = 70,
    int maxWidth = 1080,
    int maxHeight = 1080,
  });
}

/// Implementation of [ImageCompressor] using flutter_image_compress
class ImageCompressorImpl implements ImageCompressor {
  final Uuid _uuid = const Uuid();

  @override
  Future<String> compressImage({
    required String filePath,
    int quality = 70,
    int maxWidth = 1080,
    int maxHeight = 1080,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    // Get the file extension
    final extension = _getFileExtension(filePath);
    final format = _getCompressFormat(extension);

    // Generate output path in temp directory
    final tempDir = Directory.systemTemp;
    final outputPath = '${tempDir.path}/${_uuid.v4()}.$extension';

    // Compress the image
    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      outputPath,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxHeight,
      format: format,
    );

    if (result == null) {
      throw Exception('Failed to compress image');
    }

    return result.path;
  }

  @override
  Future<List<String>> compressImages({
    required List<String> filePaths,
    int quality = 70,
    int maxWidth = 1080,
    int maxHeight = 1080,
  }) async {
    final results = <String>[];

    for (final path in filePaths) {
      try {
        final compressedPath = await compressImage(
          filePath: path,
          quality: quality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );
        results.add(compressedPath);
      } catch (e) {
        // If compression fails, use original
        results.add(path);
      }
    }

    return results;
  }

  @override
  Future<Uint8List?> compressBytes({
    required Uint8List bytes,
    int quality = 70,
    int maxWidth = 1080,
    int maxHeight = 1080,
  }) async {
    return await FlutterImageCompress.compressWithList(
      bytes,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxHeight,
    );
  }

  @override
  Future<Uint8List?> compressFileToBytes({
    required String filePath,
    int quality = 70,
    int maxWidth = 1080,
    int maxHeight = 1080,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    return await FlutterImageCompress.compressWithFile(
      filePath,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxHeight,
    );
  }

  /// Get file extension from path
  String _getFileExtension(String path) {
    final extension = path.split('.').last.toLowerCase();
    // Default to jpg if extension is not recognized
    if (!['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extension)) {
      return 'jpg';
    }
    return extension == 'jpeg' ? 'jpg' : extension;
  }

  /// Get compress format from extension
  CompressFormat _getCompressFormat(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return CompressFormat.png;
      case 'webp':
        return CompressFormat.webp;
      case 'heic':
        return CompressFormat.heic;
      default:
        return CompressFormat.jpeg;
    }
  }
}
