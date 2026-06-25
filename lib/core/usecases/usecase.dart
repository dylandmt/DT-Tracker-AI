import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Base UseCase class that all use cases should extend
/// 
/// [T] is the return type of the use case
/// [Params] is the parameter type required by the use case
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// UseCase that returns a Stream instead of Future
abstract class StreamUseCase<T, Params> {
  Stream<Either<Failure, T>> call(Params params);
}

/// Parameters class for use cases that don't require any parameters
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}

/// Parameters class for use cases that require an ID
class IdParams extends Equatable {
  final String id;

  const IdParams({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Parameters class for pagination
class PaginationParams extends Equatable {
  final int page;
  final int limit;

  const PaginationParams({
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [page, limit];
}
