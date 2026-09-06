import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Opens all vehicle photos in a full-screen, swipeable gallery.
void showVehiclePhotoGallery(
  BuildContext context, {
  required List<String> imageUrls,
  required int initialIndex,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _VehiclePhotoGallery(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    ),
  );
}

class _VehiclePhotoGallery extends StatefulWidget {
  const _VehiclePhotoGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_VehiclePhotoGallery> createState() => _VehiclePhotoGalleryState();
}

class _VehiclePhotoGalleryState extends State<_VehiclePhotoGallery> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const CircularProgressIndicator(),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 16,
              child: Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
