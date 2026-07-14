part of 'events_bloc.dart';

sealed class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

class EventsSubscriptionRequested extends EventsEvent {
  const EventsSubscriptionRequested();
}

class EventsUpdated extends EventsEvent {
  final List<TrackerEventEntity>? events;
  final String? error;

  const EventsUpdated({this.events, this.error});

  @override
  List<Object?> get props => [events, error];
}

class EventReadRequested extends EventsEvent {
  final String id;
  const EventReadRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class EventArchiveRequested extends EventsEvent {
  final String id;
  const EventArchiveRequested(this.id);

  @override
  List<Object?> get props => [id];
}
