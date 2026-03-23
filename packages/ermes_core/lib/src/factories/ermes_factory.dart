
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../../ermes_core.dart';

/// Main factory implementation for creating Ermes instances

class ErmesFactory {
  ErmesFactory({
    required this.ermesBookService,
    this.defaultTimeoutMs = 30000,
  });

  final IErmesBookService<Object> ermesBookService;
  final int defaultTimeoutMs;

  /// Create a repository instance
  ///
  /// [remotePeerId] The ID of the remote peer to connect to
  /// [socket] Socket for low-level communication
  /// [ermesSignalingHandler] The signaling handler for obtaining peer
  /// connection
  /// Returns a new [IErmesRepository] instance
  IErmesRepository createRepository(
    IdAccountType remotePeerId,
    IShspSocket socket,
    IErmesSignalingHandler<ShspPeer> signalHandler, [
    int? timeoutMs,
  ]) =>
      ErmesRepository(
        remotePeerId: remotePeerId,
        socket: socket,
        signalHandler: signalHandler,
        ermesBookService: ermesBookService,
        timeoutMs: timeoutMs ?? defaultTimeoutMs,
      );

  /// Create a service instance
  ///
  /// [repository] The repository instance to use for data transport
  /// Returns a new [IErmesService] instance
  IErmesService createService(IErmesRepository repository) {
    // IA: Use real IdHandlerServiceFactory
    final idHandler = IdHandlerServiceFactory.createDefault();
    return ErmesService(repository: repository, idHandler: idHandler);
  }
}

/// Mock IdHandlerService for testing
