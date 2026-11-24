import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/design/dt_components.dart';
import '../../../../core/design/dt_design_tokens.dart';
import '../../../../config/environment/environment.dart';
import '../../../../core/security/tracker_security_dialogs.dart';
import '../../../../core/utils/image_cache.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/vehicle_color_localization.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/tracker_info.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/get_tracker_info.dart';
import '../bloc/tracker_link_bloc.dart';
import '../bloc/vehicle_form_bloc.dart';
import '../bloc/vehicles_bloc.dart';
import '../widgets/delete_vehicle_dialog.dart';
import '../widgets/tracker_status_card.dart';
import '../widgets/relay_control_card.dart';
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
                        expandedHeight: 236,
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
                              _buildVehicleHeader(context, vehicle),
                              const SizedBox(height: DTSpacing.lg),
                              Text(
                                context.l10n.vehicleDetails,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: DTSpacing.sm),
                              _buildVehicleInfoCard(context, vehicle),
                              const SizedBox(height: DTSpacing.lg),
                              Text(
                                context.l10n.tracker,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: DTSpacing.sm),

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

                              if (vehicle.hasTracker &&
                                  (vehicle.plan == VehiclePlan.protect ||
                                      vehicle.plan == VehiclePlan.total)) ...[
                                const SizedBox(height: DTSpacing.lg),
                                RelayControlCard(vehicleId: vehicle.id),
                              ],
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

  Widget _buildVehicleHeader(BuildContext context, VehicleEntity vehicle) =>
      DTGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vehicle.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DTSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DTSpacing.sm,
                vertical: DTSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .14),
                borderRadius: const BorderRadius.all(DTRadius.pill),
              ),
              child: Text(
                vehicle.plateNumber,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (vehicle.fullDescription != null) ...[
              const SizedBox(height: DTSpacing.sm),
              Text(
                vehicle.fullDescription!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (EnvironmentConfig.isDev && vehicle.plan != null) ...[
              const SizedBox(height: DTSpacing.sm),
              Text(
                '${context.l10n.vehiclePlan}: ${switch (vehicle.plan) {
                  VehiclePlan.essential => context.l10n.planEssential,
                  VehiclePlan.protect => context.l10n.planProtect,
                  VehiclePlan.total => context.l10n.planTotal,
                  null => '',
                }}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.dtColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildVehicleInfoCard(BuildContext context, VehicleEntity vehicle) =>
      DTGlassCard(
        child: Column(
          children: [
            if (vehicle.brand != null)
              _buildDetailRow(
                context,
                Icons.sell_outlined,
                context.l10n.brand,
                vehicle.brand!,
              ),
            if (vehicle.brand != null && vehicle.model != null)
              const Divider(height: DTSpacing.lg),
            if (vehicle.model != null)
              _buildDetailRow(
                context,
                Icons.directions_car_outlined,
                context.l10n.model,
                vehicle.model!,
              ),
            if ((vehicle.brand != null || vehicle.model != null) &&
                vehicle.year != null)
              const Divider(height: DTSpacing.lg),
            if (vehicle.year != null)
              _buildDetailRow(
                context,
                Icons.calendar_today_outlined,
                context.l10n.year,
                vehicle.year.toString(),
              ),
            if ((vehicle.brand != null ||
                    vehicle.model != null ||
                    vehicle.year != null) &&
                vehicle.color != null)
              const Divider(height: DTSpacing.lg),
            if (vehicle.color != null)
              _buildDetailRow(
                context,
                Icons.palette_outlined,
                context.l10n.color,
                localizedVehicleColor(context.l10n, vehicle.color!),
              ),
            const Divider(height: DTSpacing.lg),
            _buildDetailRow(
              context,
              Icons.schedule_outlined,
              context.l10n.added,
              vehicle.createdAt.localizedDate(context),
            ),
          ],
        ),
      );

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.dtColors.textSecondary),
        const SizedBox(width: DTSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.dtColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.end,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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

    final authorization = await authorizeTrackerUnlink(context);
    if (authorization != null && context.mounted) {
      context.read<TrackerLinkBloc>().add(
        UnlinkTrackerFromVehicle(vehicleId: vehicleId, pin: authorization.pin),
      );
    }
  }
}
