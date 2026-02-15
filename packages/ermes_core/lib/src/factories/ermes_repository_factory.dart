import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';

import '../ermes_repository.dart';

/// 2️⃣ Factory for creating [ErmesRepository] instances
///
/// ```
/// ┌─────────────────────────────────────┐
/// │   ErmesRepository (Transport)       │ ◄─── Factory here
/// │   - Socket connection               │
/// │   - Peer signaling                  │
/// │   - Low-level message exchange      │
/// └─────────────────────────────────────┘
///         ▲
///         │ extends ShspInstance
///         │
///    Implements IErmesRepository
/// ```
///
/// Coordinates:
/// - [PeerInfo] - Remote peer information
/// - [IShspSocket] - Transport socket connection
/// - [IdAccountType] - Remote peer identifier
/// - [IErmesSignalingHandler] - Signaling protocol handler
/// - Optional: [timeoutMs] - Connection timeout in milliseconds
///   (default: 30000)
@includeInBarrelFile
class ErmesRepositoryFactory {
  ErmesRepositoryFactory._();

  /// Creates an [ErmesRepository] with the given configuration
  ///
  /// Parameters:
  /// - [remotePeer] - Information about the remote peer
  /// - [socket] - Socket for low-level communication
  /// - [remotePeerId] - Account ID of the remote peer
  /// - [signalHandler] - Handler for SHSP signaling protocol
  /// - [timeoutMs] - Connection timeout (default: 30000ms)
  ///
  /// Returns: Configured [ErmesRepository] instance
  @includeInBarrelFile
  static ErmesRepository create({
    required PeerInfo remotePeer,
    required IShspSocket socket,
    required IdAccountType remotePeerId,
    required IErmesSignalingHandler<IShspSocket> signalHandler,
    int timeoutMs = 30000,
  }) => ErmesRepository(
    remotePeer: remotePeer,
    socket: socket,
    remotePeerId: remotePeerId,
    signalHandler: signalHandler,
    timeoutMs: timeoutMs,
  );
}
