part of 'events_bloc.dart';

class EventsState extends Equatable {
  final bool isLoading;
  final List<TrackerEventEntity> events;
  final String? errorMessage;

  const EventsState({
    this.isLoading = false,
    this.events = const [],
    this.errorMessage,
  });

  EventsState copyWith({
    bool? isLoading,
    List<TrackerEventEntity>? events,
    String? errorMessage,
  }) => EventsState(
    isLoading: isLoading ?? this.isLoading,
    events: events ?? this.events,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [isLoading, events, errorMessage];
}
