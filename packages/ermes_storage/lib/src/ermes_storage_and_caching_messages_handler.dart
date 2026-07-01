
import 'package:iermes/iermes.dart';
import 'package:work_db/work_db.dart';

import 'caching_implementation/ermes_caching_repository.dart';
import 'caching_implementation/ermes_caching_service.dart';
import 'ermes_storage_and_caching_messages.dart';
import 'storage_implementation/ermes_storage_repository.dart';

/// Message-root storage/caching layer specialised for [MessageRootStorage].
typedef ErmesStorageAndCachingMessageRoot
    = ErmesStorageAndCachingMessages<MessageRootStorage>;

/// Message storage/caching layer specialised for [MessageType].
typedef ErmesStorageAndCachingMessageType
    = ErmesStorageAndCachingMessages<MessageType>;

/// Handler base specialised for [MessageRootStorage] instances.
typedef ErmesStorageAndCachingMessagesHandlerBaseMessageRoot
    = ErmesStorageAndCachingMessagesHandlerBase<MessageRootStorage>;

    /// Handler base specialised for [MessageType] instances.
    typedef ErmesStorageAndCachingMessagesHandlerBaseMessageType
    = ErmesStorageAndCachingMessagesHandlerBase<MessageType>;

/// Base class with handler logic for managing ErmesStorageAndCachingMessages
/// instances per peer.
class ErmesStorageAndCachingMessagesHandlerBase<DataJson extends StorageType>
    implements IErmesStorageAndCachingMessagesHandlerBase<DataJson> {
  /// Map of peer storage instances keyed by IdAccountType
  final Map<IdAccountType, PeerStorageInstance> _peerInstances = {};

  /// Get or create storage instance for a specific peer
  @override
  PeerStorageInstance forPeer(IdAccountType peerId) =>
      _peerInstances.putIfAbsent(
      peerId,
      () => PeerStorageInstance(peerId),
    );

  /// Mapping of storage instances keyed by connection ID only
  final Map<IdConnectionType, ErmesStorageAndCachingMessages<DataJson>>
      _storageInstances = {};

  /// Get or retrieve a storage instance for the given connection
  @override
  ErmesStorageAndCachingMessages<DataJson>? get(
    IdConnectionType idConnectionType,
  ) =>
      _storageInstances[idConnectionType];
}

/// Singleton handler for managing ErmesStorageAndCachingMessages instances
/// per peer
class ErmesStorageAndCachingMessagesHandler
    extends ErmesStorageAndCachingMessagesHandlerBase {
  ErmesStorageAndCachingMessagesHandler._();

  static final _instance = ErmesStorageAndCachingMessagesHandler._();

  /// The shared singleton handler instance.
  static ErmesStorageAndCachingMessagesHandler get instance => _instance;
}

/// Storage instance for a single peer
class PeerStorageInstance implements IPeerStorageInstance {
  /// Creates in-memory message-root and message-type storage for [peerId].
  PeerStorageInstance(this.peerId)
      : messageRoot = ErmesStorageAndCachingMessageRoot(
          ErmesStorageRepository<MessageRootStorage>(
            WorkDb.memory(),
            'ermes_messages_root_$peerId',
          ),
          ErmesCachingService<MessageRootStorage>(
            ErmesCachingRepository<MessageRootStorage>(100),
          ),
        ),
        messageType = ErmesStorageAndCachingMessageType(
          ErmesStorageRepository<MessageType>(
            WorkDb.memory(),
            'ermes_messages_type_$peerId',
          ),
          ErmesCachingService<MessageType>(
            ErmesCachingRepository<MessageType>(100),
          ),
        );

  /// The account ID of the peer this instance stores messages for.
  @override
  final IdAccountType peerId;
  /// Storage/caching layer for message roots of this peer.
  @override
  final ErmesStorageAndCachingMessageRoot messageRoot;
  /// Storage/caching layer for typed messages of this peer.
  @override
  final ErmesStorageAndCachingMessageType messageType;
}
