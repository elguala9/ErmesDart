import 'package:iermes/iermes.dart';

import 'id_handler_repository.dart';
import 'id_handler_service.dart';

/// Factory for creating ID handler components
class IdHandlerFactory implements IIdHandlerFactory {
  @override
  IIdHandlerRepository createRepository(IdHandlerRepositoryInput input) =>
      IdHandlerRepository(
        max: input.max ?? 9007199254740991,
        start: input.start ?? 0,
      );

  @override
  IIdHandlerService createService(
    IdHandlerServiceInput input, [
    IdHandlerRepositoryInput? inputForRepo,
  ]) {
    final repository =
        createRepository(inputForRepo ?? const IdHandlerRepositoryInput());
    return IdHandlerService(
      repo: repository,
      storage: input.storage,
    );
  }
}
