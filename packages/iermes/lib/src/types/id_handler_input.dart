import '../standard_interface/i_id_handler.dart';
import '../standard_interface/i_id_handler_storage.dart';

/// Configuration input for repository ID handler
class IdHandlerRepositoryInput {
  /// Creates repository input configuration
  const IdHandlerRepositoryInput({
    this.max,
    this.start,
  });

  /// Maximum ID value (default: max safe integer)
  final int? max;

  /// Starting ID value (default: 0)
  final int? start;
}

/// Configuration input for service ID handler
class IdHandlerServiceInput {
  /// Creates service input configuration
  const IdHandlerServiceInput({
    required this.repo,
    this.storage,
  });

  /// The repository ID handler to use
  final IIdHandlerRepository repo;

  /// Optional storage for persisting ID state
  final IIdHandlerStorageService? storage;
}
