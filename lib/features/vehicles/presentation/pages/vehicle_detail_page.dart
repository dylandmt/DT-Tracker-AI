import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/security/tracker_security_dialogs.dart';
import '../../../../core/utils/image_cache.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/vehicle_color_localization.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/tracker_info.dart';
import '../../domain/usecases/get_tracker_info.dart';
import '../bloc/tracker_link_bloc.dart';
import '../bloc/vehicle_form_bloc.dart';
import '../bloc/vehicles_bloc.dart';
import '../widgets/delete_vehicle_dialog.dart';
import '../widgets/tracker_status_card.dart';
import '../widgets/vehicle_photo_gallery.dart';

/// Page displaying vehicle details
class VehicleDetailPage extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailPage({super.key, required this.vehicleId});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  TrackerStatusEntity? _trackerStatus;
  StreamSubscription? _trackerSubscription;

  @override
  void initState() {
    super.initState();
    context.read<VehicleFormBloc>().add(
      LoadVehicleForEdit(vehicleId: widget.vehicleId),
    );
  }

  void _startWatchingTracker(String trackerId) {
    _trackerSubscription?.cancel();

    final watchTrackerStatus = sl<WatchTrackerStatus>();
    _trackerSubscription = watchTrackerStatus(ImeiParams(imei: trackerId))
        .listen((result) {
          result.fold(
            (failure) {
              // Tracker status not available
              if (mounted) {
                setState(() => _trackerStatus = null);
              }
            },
            (status) {
              if (mounted) {
                setState(() => _trackerStatus = status);
              }
            },
          );
        });
  }

  @override
  void dispose() {
    _trackerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<VehiclesBloc, VehiclesState>(
      listener: (context, state) {
        if (state.hasError && state.errorMessage != null) {
          context.showErrorSnackBar(state.errorMessage!);
          context.read<VehiclesBloc>().add(const ClearVehiclesError());
        }

        if (state.isDeleted) {
          context.pop();
        }
      },
      child: BlocBuilder<VehiclesBloc, VehiclesState>(
        builder: (context, vehiclesState) {
          return BlocConsumer<VehicleFormBloc, VehicleFormState>(
            listener: (context, state) {
              if (state.hasError && state.errorMessage != null) {
                context.showErrorSnackBar(state.errorMessage!);
                context.read<VehicleFormBloc>().add(const ClearFormError());
              }

              // Start watching tracker if vehicle has one
              if (state.vehicle?.trackerId != null &&
                  _trackerSubscription == null) {
                _startWatchingTracker(state.vehicle!.trackerId!);
              }
            },
            builder: (context, state) {
              if (state.isLoading) {
                return Scaffold(
                  appBar: AppBar(title: Text(context.l10n.vehicleDetails)),
                  body: const Center(child: CircularProgressIndicator()),
                );
              }

              final vehicle = state.vehicle;
              if (vehicle == null) {
                return Scaffold(
                  appBar: AppBar(title: Text(context.l10n.vehicleDetails)),
                  body: Center(child: Text(context.l10n.vehicleNotFound)),
                );
              }

              return Scaffold(
                body: RefreshIndicator(
                  onRefresh: () => _refreshVehicle(vehicle.imageUrls),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // App Bar with image
                      SliverAppBar(
                        expandedHeight: 250,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          background: vehicle.imageUrls.isNotEmpty
                              ? _buildImageCarousel(
                                  vehicle.imageUrls,
                                  colorScheme,
                                )
                              : _buildPlaceholderImage(colorScheme),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              await context.push(
                                RouteConstants.vehicleEdit.replaceFirst(
                                  ':id',
                                  vehicle.id,
                                ),
                              );
                              if (!context.mounted) return;
                              // Reload vehicle details after returning
                              context.read<VehicleFormBloc>().add(
                                LoadVehicleForEdit(vehicleId: widget.vehicleId),
                              );
                              final refreshed = context
                                  .read<VehicleFormBloc>()
                                  .state
                                  .vehicle;
                              if (refreshed?.trackerId != null) {
                                _startWatchingTracker(refreshed!.trackerId!);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: vehiclesState.isDeleting
                                ? null
                                : () => _showDeleteDialog(context),
                          ),
                        ],
                      ),
                      // Content
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Vehicle name and plate
                              Text(
                                vehicle.name,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  vehicle.plateNumber,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Vehicle details
                              if (vehicle.fullDescription != null) ...[
                                _buildDetailRow(
                                  context,
                                  Icons.directions_car,
                                  context.l10n.vehicle,
                                  vehicle.fullDescription!,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (vehicle.color != null) ...[
                                _buildDetailRow(
                                  context,
                                  Icons.palette_outlined,
                                  context.l10n.color,
                                  localizedVehicleColor(
                                    context.l10n,
                                    vehicle.color!,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              _buildDetailRow(
                                context,
                                Icons.calendar_today_outlined,
                                context.l10n.added,
                                vehicle.createdAt.formattedDate,
                              ),

                              const SizedBox(height: 24),

                              // Tracker status card
                              BlocProvider(
                                create: (_) => sl<TrackerLinkBloc>(),
                                child: BlocConsumer<TrackerLinkBloc, TrackerLinkState>(
                                  listener: (context, trackerState) {
                                    if (trackerState.isLinked) {
                                      context.showSuccessSnackBar(
                                        context.l10n.trackerLinkedSuccessfully,
                                      );
                                      // Reload vehicle to get updated tracker info
                                      context.read<VehicleFormBloc>().add(
                                        LoadVehicleForEdit(
                                          vehicleId: widget.vehicleId,
                                        ),
                                      );
                                    }
                                    if (trackerState.isUnlinked) {
                                      context.showSuccessSnackBar(
                                        context
                                            .l10n
                                            .trackerUnlinkedSuccessfully,
                                      );
                                      _trackerSubscription?.cancel();
                                      _trackerSubscription = null;
                                      setState(() => _trackerStatus = null);
                                      // Reload vehicle
                                      context.read<VehicleFormBloc>().add(
                                        LoadVehicleForEdit(
                                          vehicleId: widget.vehicleId,
                                        ),
                                      );
                                    }
                                    if (trackerState.hasError &&
                                        trackerState.errorMessage != null) {
                                      context.showErrorSnackBar(
                                        trackerState.errorMessage!,
                                      );
                                    }
                                  },
                                  builder: (context, trackerState) {
                                    return TrackerStatusCard(
                                      vehicle: vehicle,
                                      trackerStatus: _trackerStatus,
                                      isLoading: trackerState.isLoading,
                                      onLinkTracker: () async {
                                        await context.push(
                                          '${RouteConstants.vehicleDetail.replaceFirst(':id', vehicle.id)}/link-tracker',
                                        );
                                        if (!context.mounted) return;
                                        // Reload and (re)start tracker watcher if linked
                                        context.read<VehicleFormBloc>().add(
                                          LoadVehicleForEdit(
                                            vehicleId: widget.vehicleId,
                                          ),
                                        );
                                        final refreshed = context
                                            .read<VehicleFormBloc>()
                                            .state
                                            .vehicle;
                                        if (refreshed?.trackerId != null) {
                                          _startWatchingTracker(
                                            refreshed!.trackerId!,
                                          );
                                        }
                                      },
                                      onUnlinkTracker: () => _showUnlinkDialog(
                                        context,
                                        vehicle.id,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _refreshVehicle(List<String> imageUrls) async {
    await refreshCachedImages(imageUrls);
    if (mounted) {
      context.read<VehicleFormBloc>().add(
        LoadVehicleForEdit(vehicleId: widget.vehicleId),
      );
    }
  }

  Widget _buildImageCarousel(List<String> imageUrls, ColorScheme colorScheme) {
    return PageView.builder(
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => showVehiclePhotoGallery(
            context,
            imageUrls: imageUrls,
            initialIndex: index,
          ),
          child: CachedNetworkImage(
            imageUrl: imageUrls[index],
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => _buildPlaceholderImage(colorScheme),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.directions_car_outlined,
          size: 80,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final vehicle = context.read<VehicleFormBloc>().state.vehicle;
    if (vehicle == null) return;

    final confirmed = await showDeleteVehicleDialog(context, vehicle);
    if (confirmed == true && !vehicle.hasTracker && context.mounted) {
      context.read<VehiclesBloc>().add(
        DeleteVehicleRequested(vehicleId: vehicle.id),
      );
    }
  }

  Future<void> _showUnlinkDialog(BuildContext context, String vehicleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.unlinkTracker),
        content: Text(context.l10n.unlinkTrackerConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.unlink),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final authorized = await authorizeTrackerUnlink(context);
    if (authorized && context.mounted) {
      context.read<TrackerLinkBloc>().add(
        UnlinkTrackerFromVehicle(vehicleId: vehicleId),
      );
    }
  }
}
