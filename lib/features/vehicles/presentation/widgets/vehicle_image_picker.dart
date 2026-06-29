import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/permissions/permission_handler.dart';
import '../../../../core/permissions/permission_status.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/vehicle.dart';

/// Widget for picking and displaying vehicle images
class VehicleImagePicker extends StatefulWidget {
  final VehicleEntity? vehicle;
  final List<String> imageUrls;
  final bool isUploading;
  final int? uploadingIndex;
  final ValueChanged<String>? onImageAdded;
  final ValueChanged<String>? onImageRemoved;
  final bool enabled;

  const VehicleImagePicker({
    super.key,
    this.vehicle,
    this.imageUrls = const [],
    this.isUploading = false,
    this.uploadingIndex,
    this.onImageAdded,
    this.onImageRemoved,
    this.enabled = true,
  });

  @override
  State<VehicleImagePicker> createState() => _VehicleImagePickerState();
}

class _VehicleImagePickerState extends State<VehicleImagePicker> {
  final ImagePicker _picker = ImagePicker();
  final AppPermissionHandler _permissionHandler = sl<AppPermissionHandler>();

  int get _currentCount => widget.imageUrls.length;
  int get _remainingSlots => VehicleEntity.maxImages - _currentCount;
  bool get _canAddMore => _remainingSlots > 0 && widget.enabled;

  Future<void> _pickImage(ImageSource source) async {
    if (!_canAddMore) return;

    // Check permission
    final permission = source == ImageSource.camera
        ? AppPermission.camera
        : AppPermission.photos;

    final hasPermission = await _permissionHandler.ensurePermission(permission);

    if (!hasPermission) {
      if (mounted) {
        final requiresSettings =
            await _permissionHandler.requiresSettings(permission);
        if (requiresSettings) {
          _showSettingsDialog(permission);
        }
      }
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        widget.onImageAdded?.call(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(AppPermission permission) {
    final permissionName =
        permission == AppPermission.camera ? 'Camera' : 'Photo Library';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Access Required'),
        content: Text(
          'Please enable $permissionName access in Settings to add photos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _permissionHandler.openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Photos',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '($_currentCount/${VehicleEntity.maxImages})',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Images grid
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _currentCount + (_canAddMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              // Add button
              if (index == _currentCount) {
                return _buildAddButton(colorScheme);
              }

              // Image item
              final imageUrl = widget.imageUrls[index];
              final isUploading =
                  widget.isUploading && widget.uploadingIndex == index;

              return _buildImageItem(
                imageUrl,
                index,
                isUploading,
                colorScheme,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(ColorScheme colorScheme) {
    return InkWell(
      onTap: widget.enabled ? _showImageSourceDialog : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.5),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32,
              color: widget.enabled
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 12,
                color: widget.enabled
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(
    String imageUrl,
    int index,
    bool isUploading,
    ColorScheme colorScheme,
  ) {
    return Stack(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 100,
            height: 100,
            child: imageUrl.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: colorScheme.errorContainer,
                      child: Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  )
                : Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          ),
        ),
        // Loading overlay
        if (isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        // Remove button
        if (!isUploading && widget.enabled)
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => widget.onImageRemoved?.call(imageUrl),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: colorScheme.onError,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
