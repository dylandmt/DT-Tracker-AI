import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/permissions/permission_handler.dart';
import '../../../../core/permissions/permission_status.dart';
import '../../../../core/utils/image_cache.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/profile_photo_preview.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _secondLastNameController = TextEditingController();

  final _imagePicker = ImagePicker();
  final _permissionHandler = sl<AppPermissionHandler>();

  String? _selectedImagePath;
  String? _initializedUserId;

  UserGender? _selectedGender;
  DateTime? _selectedBirthDate;

  bool _isSaving = false;
  bool _isRefreshing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final user = context.read<AuthBloc>().state.user;

    if (user != null && user.id != _initializedUserId) {
      _initializedUserId = user.id;
      _populateProfile(user);
    }
  }

  void _populateProfile(UserEntity user) {
    _firstNameController.text = user.firstName ?? '';
    _lastNameController.text = user.lastName ?? '';
    _secondLastNameController.text = user.secondLastName ?? '';
    _selectedGender = user.gender;
    _selectedBirthDate = user.birthDate;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _secondLastNameController.dispose();

    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final hasPermission = await _permissionHandler.ensurePermission(
        AppPermission.camera,
      );

      if (!hasPermission) {
        if (!mounted) {
          return;
        }

        context.showErrorSnackBar(context.l10n.cameraPermissionDenied);

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
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar(context.l10n.unableToSelectProfilePhoto);
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(context.l10n.takePhoto),
                onTap: () {
                  Navigator.pop(sheetContext);

                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.l10n.chooseFromGallery),
                onTap: () {
                  Navigator.pop(sheetContext);

                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    setState(() {
      _selectedBirthDate = selectedDate;
    });
  }

  void _saveProfile() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final firstName = _firstNameController.text.trim();

    final lastName = _lastNameController.text.trim();

    final secondLastName = _secondLastNameController.text.trim();

    setState(() {
      _isSaving = true;
    });

    context.read<AuthBloc>().add(
      ProfileUpdateRequested(
        firstName: firstName,
        lastName: lastName,
        secondLastName: secondLastName.isEmpty ? null : secondLastName,
        gender: _selectedGender,
        birthDate: _selectedBirthDate,
        imagePath: _selectedImagePath,
      ),
    );
  }

  String _formatBirthDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _avatarInitial(UserEntity user) {
    final fullName = user.fullName.trim();

    if (fullName.isNotEmpty) {
      return fullName.substring(0, 1).toUpperCase();
    }

    if (user.email.isNotEmpty) {
      return user.email.substring(0, 1).toUpperCase();
    }

    return '?';
  }

  Future<void> _refreshProfile(String? photoUrl) async {
    await refreshCachedImages([photoUrl]);
    if (mounted) {
      _isRefreshing = true;
      context.read<AuthBloc>().add(CheckAuthStatus());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profile)),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (_isRefreshing && state.isAuthenticated && state.user != null) {
            _populateProfile(state.user!);
            _isRefreshing = false;
          }
          if (!_isSaving) {
            return;
          }

          if (state.hasError) {
            setState(() {
              _isSaving = false;
            });

            return;
          }

          if (state.isProfileUpdated) {
            setState(() {
              _isSaving = false;
            });

            context.showSuccessSnackBar(context.l10n.profileUpdated);

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

            final ImageProvider? imageProvider = _selectedImagePath != null
                ? FileImage(File(_selectedImagePath!))
                : user.photoUrl != null
                ? CachedNetworkImageProvider(user.photoUrl!)
                : null;

            final heroTag = 'profile-photo-${user.id}';

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: () => _refreshProfile(user.photoUrl),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: imageProvider == null
                                  ? null
                                  : () {
                                      showProfilePhotoPreview(
                                        context,
                                        imageProvider: imageProvider,
                                        heroTag: heroTag,
                                      );
                                    },
                              child: Hero(
                                tag: heroTag,
                                child: CircleAvatar(
                                  radius: 56,
                                  backgroundImage: imageProvider,
                                  child: imageProvider == null
                                      ? Text(
                                          _avatarInitial(user),
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
                                tooltip: context.l10n.changeProfilePhoto,
                                onPressed: isBusy
                                    ? null
                                    : _showImageSourcePicker,
                                icon: const Icon(Icons.camera_alt_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _firstNameController,
                        enabled: !isBusy,
                        decoration: InputDecoration(
                          labelText: context.l10n.firstName,
                          hintText: context.l10n.enterYourFirstName,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n.enterYourFirstName;
                          }

                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _lastNameController,
                        enabled: !isBusy,
                        decoration: InputDecoration(
                          labelText: context.l10n.lastName,
                          hintText: context.l10n.enterYourLastName,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n.enterYourLastName;
                          }

                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _secondLastNameController,
                        enabled: !isBusy,
                        decoration: InputDecoration(
                          labelText: context.l10n.secondLastName,
                          hintText: context.l10n.enterYourSecondLastName,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<UserGender>(
                        initialValue: _selectedGender,
                        decoration: InputDecoration(
                          labelText: context.l10n.gender,
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: UserGender.male,
                            child: Text(context.l10n.male),
                          ),
                          DropdownMenuItem(
                            value: UserGender.female,
                            child: Text(context.l10n.female),
                          ),
                          DropdownMenuItem(
                            value: UserGender.other,
                            child: Text(context.l10n.other),
                          ),
                          DropdownMenuItem(
                            value: UserGender.preferNotToSay,
                            child: Text(context.l10n.preferNotToSay),
                          ),
                        ],
                        onChanged: isBusy
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },
                      ),

                      const SizedBox(height: 16),

                      InkWell(
                        onTap: isBusy ? null : _selectBirthDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: context.l10n.birthDate,
                            prefixIcon: const Icon(Icons.cake_outlined),
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                          ),
                          child: Text(
                            _selectedBirthDate == null
                                ? context.l10n.selectBirthDate
                                : _formatBirthDate(_selectedBirthDate!),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: user.email,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: context.l10n.email,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        context.l10n.emailCannotBeChanged,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),

                      const SizedBox(height: 32),

                      FilledButton(
                        onPressed: isBusy ? null : _saveProfile,
                        child: isBusy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(context.l10n.saveChanges),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
