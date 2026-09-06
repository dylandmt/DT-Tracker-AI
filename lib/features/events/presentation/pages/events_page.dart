import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/tracker_event.dart';
import '../bloc/events_bloc.dart';
import '../utils/localized_tracker_event.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  @override
  void initState() {
    super.initState();
    context.read<EventsBloc>().add(const EventsSubscriptionRequested());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context)!.events)),
    body: BlocConsumer<EventsBloc, EventsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          context.showErrorSnackBar(state.errorMessage!);
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.events.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () async => context.read<EventsBloc>().add(
            const EventsSubscriptionRequested(),
          ),
          child: state.events.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 180),
                    Center(
                      child: Text(
                        AppLocalizations.of(context)!.noTrackerEvents,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _EventTile(event: state.events[index]),
                ),
        );
      },
    ),
  );
}

class _EventTile extends StatelessWidget {
  final TrackerEventEntity event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final localizedEvent = localizedTrackerEvent(
      AppLocalizations.of(context)!,
      event,
    );
    final icon = switch (event.eventType) {
      TrackerEventType.geofenceEnter => Icons.login,
      TrackerEventType.geofenceExit => Icons.logout,
      TrackerEventType.unknown => Icons.notifications_outlined,
    };
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(localizedEvent.title),
        subtitle: Text(
          '${localizedEvent.message}\n${event.occurredAt.localizedDateTime(context)}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: AppLocalizations.of(context)!.archiveEvent,
          icon: const Icon(Icons.archive_outlined),
          onPressed: () =>
              context.read<EventsBloc>().add(EventArchiveRequested(event.id)),
        ),
        onTap: event.isRead
            ? null
            : () =>
                  context.read<EventsBloc>().add(EventReadRequested(event.id)),
      ),
    );
  }
}
