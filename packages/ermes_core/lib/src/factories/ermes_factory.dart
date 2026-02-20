import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

import '../../ermes_core.dart';

/// Main factory implementation for creating Ermes instances
@includeInBarrelFile
class ErmesFactory {
  ErmesFactory({
    required this.ermesBookService,
    this.defaultTimeoutMs = 30000,
  });

  final IErmesBookService<dynamic> ermesBookService;
  final int defaultTimeoutMs;

  /// Create a repository instance
  ///
  /// [remotePeerId] The ID of the remote peer to connect to
  /// [socket] Socket for low-level communication
  /// [ermesSignalingHandler] The signaling handler for obtaining peer
  /// connection
  /// Returns a new [IErmesRepository] instance
  Future<IErmesRepository> createRepository(
    IdAccountType remotePeerId,
    IShspSocket socket,
    IErmesSignalingHandler<IShspSocket> signalHandler, [
    int? timeoutMs,
  ]) async {
    final peerInfo = await ermesBookService.getPeerInfo(remotePeerId);
    if (peerInfo == null) {
      throw Exception(
        'Peer info not found for account $remotePeerId',
      );
    }

    return ErmesRepository(
      remotePeer: peerInfo,
      socket: socket,
      remotePeerId: remotePeerId,
      signalHandler: signalHandler,
      timeoutMs: timeoutMs ?? defaultTimeoutMs,
    );
  }

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
