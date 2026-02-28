import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import '../ermes_send_repo.dart';

/// 3️⃣ Factory for creating [ErmesSendRepo] instances
///
/// ```
/// ┌──────────────────────────────────┐
/// │  ErmesSendRepo (Send/Write)      │ ◄─── Factory here
/// │  - Message fragmentation         │
/// │  - Integrity checking            │
/// │  - ID generation for messages    │
/// └──────────────────────────────────┘
///         ▲
///         │ manages
///         │
/// Uses: IErmesRepository + IIdHandlerService
/// ```
///
/// Coordinates:
/// - [IErmesRepository] - Transport layer for sending
/// - [IIdHandlerService] - Service for generating message IDs
/// - Optional: [maxByte] - Maximum message chunk size (default: 1024)

class ErmesSendRepoFactory {
  ErmesSendRepoFactory._();

  /// Creates an [ErmesSendRepo] with the given dependencies
  ///
  /// Parameters:
  /// - [repository] - Transport repository for sending messages
  /// - [idHandler] - Service for generating unique message IDs
  /// - [maxByte] - Maximum bytes per fragment (default: 1024)
  ///
  /// Returns: Configured [ErmesSendRepo] instance
  
  static ErmesSendRepo create({
    required IErmesRepository repository,
    required IIdHandlerService idHandler,
    int maxByte = 1024,
  }) => ErmesSendRepo(repository, idHandler,  maxByte);
}
