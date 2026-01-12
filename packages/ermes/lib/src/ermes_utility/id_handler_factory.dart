import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import '../ermes_implementation/id_handler/id_handler_repository.dart';
import '../ermes_implementation/id_handler/id_handler_service.dart';

/// Factory for creating ID handler components
@includeInBarrelFile
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
  /// [input] Configuration for the service ID handler (all fields optional)
  /// [inputForRepo] Configuration for the internal repository (used if
  /// input.repo is null)
  /// Returns a new [IIdHandlerService] instance
  static IIdHandlerService createService(
    IdHandlerServiceInput input, [
    IdHandlerRepositoryInput? inputForRepo,
  ]) {
    final repository = createRepository(
      inputForRepo ?? const IdHandlerRepositoryInput(),
    );
    return IdHandlerService(repo: repository, storage: input.storage);
  }
}
