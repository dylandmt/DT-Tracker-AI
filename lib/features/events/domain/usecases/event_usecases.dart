import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/tracker_event.dart';
import '../repositories/event_repository.dart';

class WatchEvents implements StreamUseCase<List<TrackerEventEntity>, NoParams> {
  final EventRepository repository;
  WatchEvents(this.repository);

  @override
  Stream<Either<Failure, List<TrackerEventEntity>>> call(NoParams params) =>
      repository.watchEvents();
}

class MarkEventAsRead implements UseCase<void, IdParams> {
  final EventRepository repository;
  MarkEventAsRead(this.repository);

  @override
  Future<Either<Failure, void>> call(IdParams params) =>
      repository.markAsRead(params.id);
}

class ArchiveEvent implements UseCase<void, IdParams> {
  final EventRepository repository;
  ArchiveEvent(this.repository);

  @override
  Future<Either<Failure, void>> call(IdParams params) =>
      repository.archive(params.id);
}
