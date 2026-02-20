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
/// - [IShspSocket] - Transport socket connection
/// - [IdAccountType] - Remote peer identifier
/// - [IErmesSignalingHandler] - Signaling protocol handler
/// - [IErmesBookService] - Service to retrieve peer information
/// - Optional: [timeoutMs] - Connection timeout in milliseconds
///   (default: 30000)
@includeInBarrelFile
class ErmesRepositoryFactory {
  ErmesRepositoryFactory._();

  /// Creates an [ErmesRepository] with the given configuration
  ///
  /// Parameters:
  /// - [remotePeerId] - Account ID of the remote peer
  /// - [socket] - Socket for low-level communication
  /// - [signalHandler] - Handler for SHSP signaling protocol
  /// - [ermesBookService] - Service to retrieve peer information
  /// - [timeoutMs] - Connection timeout (default: 30000ms)
  ///
  /// Returns: Configured [ErmesRepository] instance
  @includeInBarrelFile
  static Future<ErmesRepository> create({
    required IdAccountType remotePeerId,
    required IShspSocket socket,
    required IErmesSignalingHandler<IShspSocket> signalHandler,
    required IErmesBookService ermesBookService,
    int timeoutMs = 30000,
  }) =>
      ErmesRepository.create(
        remotePeerId: remotePeerId,
        socket: socket,
        signalHandler: signalHandler,
        ermesBookService: ermesBookService,
        timeoutMs: timeoutMs,
      );
}
