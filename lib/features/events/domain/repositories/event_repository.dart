import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/tracker_event.dart';

abstract class EventRepository {
  Stream<Either<Failure, List<TrackerEventEntity>>> watchEvents();
  Future<Either<Failure, void>> markAsRead(String eventId);
  Future<Either<Failure, void>> archive(String eventId);
}
