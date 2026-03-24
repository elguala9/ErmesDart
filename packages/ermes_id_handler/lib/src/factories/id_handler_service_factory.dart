
import 'package:iermes/iermes.dart';

import '../handlers/id_handler_repository.dart';
import '../handlers/id_handler_service.dart';

/// Factory for creating IIdHandlerService instances

class IdHandlerServiceFactory {
  IdHandlerServiceFactory._();

  /// Create an IIdHandlerService with optional custom repository
  /// configuration
  ///
  /// [repositoryInput] Optional custom repository input - if not provided,
  /// uses defaults
  /// [storage] Optional storage handler for persisting IDs
  /// Returns a new [IIdHandlerService] instance
  static IIdHandlerService create({
    IdHandlerRepositoryInput? repositoryInput,
    IIdHandlerStorageService? storage,
  }) {
    final repoInput = repositoryInput ?? const IdHandlerRepositoryInput();
    final repository = IdHandlerRepository(
      max: repoInput.max ?? 9007199254740991,
      start: repoInput.start ?? 0,
    );
    return IdHandlerService.fromRepo(repo: repository, storage: storage);
  }

  /// Create an IIdHandlerService with default configuration
  ///
  /// Returns a new [IIdHandlerService] instance with default settings
  static IIdHandlerService createDefault() => create();

  /// Create an IIdHandlerService with custom storage
  ///
  /// [storage] The storage handler to use for persisting IDs
  /// Returns a new [IIdHandlerService] instance
  static IIdHandlerService createWithStorage(
    IIdHandlerStorageService storage,
  ) => create(storage: storage);

  /// Create an IIdHandlerService with custom range
  ///
  /// [start] The starting ID value
  /// [max] The maximum ID value
  /// Returns a new [IIdHandlerService] instance
  static IIdHandlerService createWithRange({
    required int start,
    required int max,
  }) => create(
    repositoryInput: IdHandlerRepositoryInput(start: start, max: max),
  );
}
