import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/extensions.dart';
import '../../domain/entities/tracker_event.dart';
import '../bloc/events_bloc.dart';

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
    appBar: AppBar(title: const Text('Events')),
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
        if (state.events.isEmpty) {
          return const Center(child: Text('No tracker events yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _EventTile(event: state.events[index]),
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
    final icon = switch (event.eventType) {
      TrackerEventType.geofenceEnter => Icons.login,
      TrackerEventType.geofenceExit => Icons.logout,
      TrackerEventType.unknown => Icons.notifications_outlined,
    };
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(event.title),
        subtitle: Text(
          '${event.message}\n${event.occurredAt.toLocal().formattedDateTime}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Archive event',
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
