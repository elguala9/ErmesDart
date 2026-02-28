import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import 'id_handler_repository.dart';
import 'id_handler_service.dart';

/// Factory for creating ID handler components

class IdHandlerFactory {
  IdHandlerFactory._();

  /// Create a repository ID handler
  ///
  /// [input] Configuration for the ID handler
  /// Returns a new [IIdHandlerRepository] instance
  static IIdHandlerRepository createRepository(
    IdHandlerRepositoryInput input,
  ) => IdHandlerRepository(
    max: input.max ?? 9007199254740991,
    start: input.start ?? 0,
  );

  /// Create a service ID handler
  ///
  /// [input] Configuration for the service ID handler
  /// [inputForRepo] Configuration for the internal repository (used if
  /// input.repo is null)
  /// Returns a new [IIdHandlerService] instance
  static IIdHandlerService createService(
    IdHandlerServiceInput input, [
    IdHandlerRepositoryInput? inputForRepo,
  ]) {
    // Use the repository from input, or create one from inputForRepo
    final repository = inputForRepo != null
        ? createRepository(inputForRepo)
        : input.repo;
    return IdHandlerService(repo: repository, storage: input.storage);
  }
}
