import 'package:cached_network_image/cached_network_image.dart';

/// Removes remote images from disk and memory so a manual refresh fetches them again.
Future<void> refreshCachedImages(Iterable<String?> imageUrls) async {
  await Future.wait(
    imageUrls.whereType<String>().map(CachedNetworkImage.evictFromCache),
  );
}
