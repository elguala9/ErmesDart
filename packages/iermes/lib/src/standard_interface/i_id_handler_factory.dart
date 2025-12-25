import '../types/id_handler_input.dart';
import 'i_id_handler.dart';

/// Factory interface for creating ID handlers
///
/// This factory creates ID handler instances for both repository and service
/// layers.
abstract class IIdHandlerFactory {
  /// Create a repository ID handler
  ///
  /// [input] Configuration for the ID handler
  /// Returns a new [IIdHandlerRepository] instance
  IIdHandlerRepository createRepository(IdHandlerRepositoryInput input);

  /// Create a service ID handler
  ///
  /// [input] Configuration for the service ID handler (all fields optional)
  /// [inputForRepo] Configuration for the internal repository (used if
  /// input.repo is null)
  /// Returns a new [IIdHandlerService] instance
  IIdHandlerService createService(
    IdHandlerServiceInput input, [
    IdHandlerRepositoryInput? inputForRepo,
  ]);
}
