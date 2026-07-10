import 'package:flutter/material.dart';

void showProfilePhotoPreview(
  BuildContext context, {
  required ImageProvider imageProvider,
  required String heroTag,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      pageBuilder: (_, __, ___) =>
          _ProfilePhotoPreview(imageProvider: imageProvider, heroTag: heroTag),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _ProfilePhotoPreview extends StatelessWidget {
  final ImageProvider imageProvider;
  final String heroTag;

  const _ProfilePhotoPreview({
    required this.imageProvider,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Hero(
                  tag: heroTag,
                  child: Image(image: imageProvider, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                tooltip: 'Close preview',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
