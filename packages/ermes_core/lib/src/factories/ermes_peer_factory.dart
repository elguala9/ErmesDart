import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';

import '../ermes_peer.dart';
import 'ermes_repository_factory.dart';
import 'ermes_service_factory.dart';

/// Configuration object for creating ErmesPeer instances
///
/// Aggregates all parameters needed to instantiate and configure a peer
/// connection, including transport, service options, and storage.
@includeInBarrelFile
class ErmesPeerConfig {
  /// Creates a configuration for ErmesPeer
  const ErmesPeerConfig({
    required this.remotePeerId,
    required this.socket,
    required this.signalingHandler,
    required this.ermesBookService,
    required this.idHandler,
    this.storageAndCaching,
    this.messageControlService,
    this.missingMessagesCheckIntervalMs,
    this.missingMessagesThreshold,
    this.timeoutMs = 30000,
    this.maxBufferSize,
    this.maxMessageSize,
    this.enableEncryption = true,
    this.keyRotationIntervalMessages = 1000,
    this.keyRotationIntervalSeconds = 3600,
  });

  /// Account ID of the remote peer
  final IdAccountType remotePeerId;

  /// Socket for low-level communication
  final IShspSocket socket;

  /// Handler for SHSP signaling protocol
  final IErmesSignalingHandler<IShspSocket> signalingHandler;

  /// Service to retrieve peer information
  final IErmesBookService ermesBookService;

  /// Service for ID generation and tracking
  final IIdHandlerService idHandler;

  /// Optional storage and caching service for both ErmesService and
  /// ErmesPeer offline queue
  final IErmesStorageAndCaching? storageAndCaching;

  /// Optional service for missing message control
  final IErmesMessageControlService? messageControlService;

  /// Interval (ms) for periodic missing message checks
  final int? missingMessagesCheckIntervalMs;

  /// Threshold of missing IDs before automatic request
  final int? missingMessagesThreshold;

  /// Connection timeout in milliseconds (default: 30000)
  final int timeoutMs;

  /// Maximum buffer size for message assembly (default: 100)
  final int? maxBufferSize;

  /// Maximum individual message size in bytes (default: 65KB)
  final int? maxMessageSize;

  /// Enable encryption for peer communication (default: true)
  final bool enableEncryption;

  /// Number of messages before initiating key rotation (default: 1000)
  final int keyRotationIntervalMessages;

  /// Time in seconds before initiating key rotation (default: 3600 = 1 hour)
  final int keyRotationIntervalSeconds;
}

/// Factory for creating and configuring ErmesPeer instances
///
/// Orchestrates the creation of all required components:
/// - ErmesRepository for transport
/// - ErmesService for messaging protocol
/// - ErmesConnection for connection management
/// - ErmesPeer facade for user-facing API
///
/// Example usage:
/// ```dart
/// final config = ErmesPeerConfig(
///   remotePeerId: 'alice',
///   socket: mySocket,
///   signalingHandler: myHandler,
///   ermesBookService: myBook,
///   idHandler: myIdHandler,
/// );
///
/// final peer = ErmesPeerFactory.create(config);
/// await peer.initialize(initiateKeyExchange: true);
/// ```
@includeInBarrelFile
class ErmesPeerFactory {
  ErmesPeerFactory._();

  /// Creates a fully configured ErmesPeer instance
  ///
  /// Internally:
  /// 1. Creates ErmesRepository via ErmesRepositoryFactory.create()
  /// 2. Creates ErmesService via ErmesServiceFactory.createService()
  /// 3. Creates ErmesConnection wrapping the service and repository
  /// 4. Returns ErmesPeer facade aggregating the above components
  ///
  /// [config] Configuration object with all required parameters
  ///
  /// Returns: A configured ErmesPeer instance ready for use
  @includeInBarrelFile
  static ErmesPeer create(ErmesPeerConfig config) {
    // Step 1: Create the transport repository
    final repository = ErmesRepositoryFactory.create(
      remotePeerId: config.remotePeerId,
      socket: config.socket,
      signalHandler: config.signalingHandler,
      ermesBookService: config.ermesBookService,
      timeoutMs: config.timeoutMs,
    );

    // Step 2: Create the messaging service
    final service = ErmesServiceFactory.createService(
      config.maxBufferSize,
      config.maxMessageSize,
      repository,
      config.idHandler,
      null, // callbackOnDataArrived - will be registered on demand
      config.storageAndCaching,
      config.messageControlService,
      config.missingMessagesCheckIntervalMs,
      config.missingMessagesThreshold,
    );

    // Step 3: Create and return the peer facade
    return ErmesPeer.create(
      service: service,
      remotePeerId: config.remotePeerId,
      enableEncryption: config.enableEncryption,
      keyRotationIntervalMessages: config.keyRotationIntervalMessages,
      keyRotationIntervalSeconds: config.keyRotationIntervalSeconds,
    );
  }
}
