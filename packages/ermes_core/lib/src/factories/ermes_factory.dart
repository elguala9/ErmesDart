import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';
import 'package:shsp_implementations/shsp_implementations.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

import '../../ermes_core.dart';

/// Main factory implementation for creating Ermes instances
@includeInBarrelFile
class ErmesFactory {
  ErmesFactory({this.defaultTimeoutMs = 30000});

  final int defaultTimeoutMs;

  /// Create a repository instance
  ///
  /// [remotePeerId] The ID of the remote peer to connect to
  /// [ermesSignalingHandler] The signaling handler for obtaining peer
  /// connection
  /// Returns a new [IErmesRepository] instance
  IErmesRepository createRepository(
    PeerInfo peerInfo,
    IdAccountType remotePeerId,
    IErmesSignalingHandler<ShspSocket> signalHandler,
    int timeoutMs,
    IShspSocket socket,
  ) => ErmesRepository(
    remotePeer: peerInfo,
    socket: socket,
    remotePeerId: remotePeerId,
    signalHandler: signalHandler,
    timeoutMs: defaultTimeoutMs,
  );

  /// Create a service instance
  ///
  /// [repository] The repository instance to use for data transport
  /// Returns a new [IErmesService] instance
  IErmesService createService(IErmesRepository repository) {
    // TODO: Create proper IdHandler
    final idHandler = _createMockIdHandler();

    return ErmesService(repository: repository, idHandler: idHandler);
  }

  // Mock ID handler for now
  IIdHandlerService _createMockIdHandler() => _MockIdHandlerService();
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

  @override
  void setCounter(IdType counter) {
    _counter = counter;
  }

  @override
  IdType getCurrent() => _counter;
}
