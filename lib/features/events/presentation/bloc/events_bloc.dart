import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/tracker_event.dart';
import '../../domain/usecases/event_usecases.dart';

part 'events_event.dart';
part 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final WatchEvents watchEvents;
  final MarkEventAsRead markEventAsRead;
  final ArchiveEvent archiveEvent;
  StreamSubscription? _subscription;

  EventsBloc({
    required this.watchEvents,
    required this.markEventAsRead,
    required this.archiveEvent,
  }) : super(const EventsState()) {
    on<EventsSubscriptionRequested>(_subscribe);
    on<EventsUpdated>(_updated);
    on<EventReadRequested>(_markRead);
    on<EventArchiveRequested>(_archive);
  }

  void _subscribe(
    EventsSubscriptionRequested event,
    Emitter<EventsState> emit,
  ) {
    _subscription?.cancel();
    emit(state.copyWith(isLoading: true, errorMessage: null));
    _subscription = watchEvents(const NoParams()).listen(
      (result) => result.fold(
        (failure) => add(EventsUpdated(error: failure.message)),
        (events) => add(EventsUpdated(events: events)),
      ),
      onError: (Object error) => add(EventsUpdated(error: error.toString())),
    );
  }

  void _updated(EventsUpdated event, Emitter<EventsState> emit) => emit(
    state.copyWith(
      isLoading: false,
      events: event.events,
      errorMessage: event.error,
    ),
  );

  Future<void> _markRead(
    EventReadRequested event,
    Emitter<EventsState> emit,
  ) async {
    final result = await markEventAsRead(IdParams(id: event.id));
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {},
    );
  }

  Future<void> _archive(
    EventArchiveRequested event,
    Emitter<EventsState> emit,
  ) async {
    final result = await archiveEvent(IdParams(id: event.id));
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {},
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
