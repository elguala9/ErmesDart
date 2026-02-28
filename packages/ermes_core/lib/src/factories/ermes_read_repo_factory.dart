
import 'package:iermes/iermes.dart';

import '../ermes_read_repo.dart';

/// 4️⃣ Factory for creating [ErmesReadRepo] instances
///
/// ```
/// ┌──────────────────────────────────┐
/// │  ErmesReadRepo (Read/Receive)    │ ◄─── Factory here
/// │  - Message buffering             │
/// │  - Chunk reassembly              │
/// │  - Message callbacks             │
/// └──────────────────────────────────┘
///         ▲
///         │ manages
///         │
/// Uses: IErmesRepository + IErmesMessageControlService (optional)
/// ```
///
/// Coordinates:
/// - [IErmesRepository] - Transport layer for receiving
/// - [callbackServiceMessage] - Callback for service/control messages
/// - Optional: [messageControlService] - Service to track message delivery
/// - [options] - Configuration for buffering and callbacks

class ErmesReadRepoFactory {
  ErmesReadRepoFactory._();

  /// Creates an [ErmesReadRepo] with the given dependencies
  ///
  /// Parameters:
  /// - [repository] - Transport repository for receiving messages
  /// - [onServiceMessage] - Callback triggered for service/control messages
  /// - [options] - Configuration options (buffer size, callbacks)
  /// - [messageControlService] - Optional service for tracking message state
  ///
  /// Returns: Configured [ErmesReadRepo] instance
  
  static ErmesReadRepo create({
    required IErmesRepository repository,
    required void Function(ServiceMessage serviceMessage) onServiceMessage,
    required ErmesReadRepoOptions options,
    IErmesMessageControlService? messageControlService,
  }) => ErmesReadRepo(
    repository,
    onServiceMessage,
    messageControlService,
    options,
  );
}
