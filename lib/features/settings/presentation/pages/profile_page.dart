import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/permissions/permission_handler.dart';
import '../../../../core/permissions/permission_status.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../widgets/profile_photo_preview.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _permissionHandler = sl<AppPermissionHandler>();

  String? _selectedImagePath;
  String? _initializedUserId;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthBloc>().state.user;
    if (user != null && user.id != _initializedUserId) {
      _initializedUserId = user.id;
      _displayNameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final hasPermission = await _permissionHandler.ensurePermission(
        AppPermission.camera,
      );
      if (!hasPermission) {
        if (!mounted) return;
        context.showErrorSnackBar('Camera permission denied');
        return;
      }
    }

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() => _selectedImagePath = image.path);
      }
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar('Unable to select profile photo');
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    context.read<AuthBloc>().add(
      ProfileUpdateRequested(
        displayName: _displayNameController.text.trim(),
        imagePath: _selectedImagePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (!_isSaving) return;

          if (state.hasError) {
            setState(() => _isSaving = false);
            return;
          }

          if (state.isProfileUpdated) {
            setState(() => _isSaving = false);
            context.showSuccessSnackBar('Profile updated');
            context.pop();
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state.user;
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final isBusy = _isSaving || state.isLoading;
            final imageProvider = _selectedImagePath != null
                ? FileImage(File(_selectedImagePath!)) as ImageProvider
                : user.photoUrl != null
                ? NetworkImage(user.photoUrl!)
                : null;
            final heroTag = 'profile-photo-${user.id}';

            return SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: imageProvider == null
                                ? null
                                : () => showProfilePhotoPreview(
                                    context,
                                    imageProvider: imageProvider,
                                    heroTag: heroTag,
                                  ),
                            child: Hero(
                              tag: heroTag,
                              child: CircleAvatar(
                                radius: 56,
                                backgroundImage: imageProvider,
                                child: imageProvider == null
                                    ? Text(
                                        (user.displayName ?? user.email)
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineMedium,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: IconButton.filled(
                              tooltip: 'Change profile photo',
                              onPressed: isBusy ? null : _showImageSourcePicker,
                              icon: const Icon(Icons.camera_alt_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    NameTextField(
                      controller: _displayNameController,
                      validator: Validators.validateDisplayName,
                      enabled: !isBusy,
                      onFieldSubmitted: (_) => _saveProfile(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: user.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your email address cannot be changed here.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: isBusy ? null : _saveProfile,
                      child: isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save changes'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
