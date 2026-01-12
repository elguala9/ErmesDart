import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

import '../ermes_service.dart';

/// Main factory implementation for creating Ermes instances
@includeInBarrelFile
class ErmesFactory<SocketType> implements IErmesFactory<SocketType> {
  ErmesFactory({this.defaultTimeoutMs = 30000});

  final int defaultTimeoutMs;

  /// Create a repository instance
  ///
  /// [remotePeerId] The ID of the remote peer to connect to
  /// [ermesSignalingHandler] The signaling handler for peer setup
  /// Returns a new [IErmesRepository] instance
  @override
  Future<IErmesRepository> createRepository(
    IdAccountType remotePeerId,
    IErmesSignalingHandler<SocketType> ermesSignalingHandler,
  ) async {
    // TODO: Implement repository creation with proper ShspPeer integration
    // For now, throw an error since we need more ShspPeer details
    throw UnimplementedError(
      'Repository creation requires SHSP socket integration',
    );
  }

  /// Create a service instance
  ///
  /// [repository] The repository instance to use for data transport
  /// Returns a new [IErmesService] instance
  @override
  IErmesService createService(IErmesRepository repository) {
    // TODO: Create proper IdHandler
    final idHandler = _createMockIdHandler();

    return ErmesService(repository: repository, idHandler: idHandler);
  }

  // Mock ID handler for now
  IIdHandlerService _createMockIdHandler() => _MockIdHandlerService();

  /// Create both repository and service instances
  ///
  /// This is a convenience method that creates both instances with
  /// the service properly connected to the repository.
  Future<(IErmesRepository, IErmesService)> createBoth(
    IdAccountType remotePeerId,
    IErmesSignalingHandler<SocketType> ermesSignalingHandler,
  ) async {
    final repository = await createRepository(
      remotePeerId,
      ermesSignalingHandler,
    );
    final service = createService(repository);
    return (repository, service);
  }
}

/// Mock IdHandlerService for testing
class _MockIdHandlerService implements IIdHandlerService {
  int _counter = 0;

  @override
  IdType getNewId() => _counter++;

  @override
  void reset() {
    _counter = 0;
  }
}
