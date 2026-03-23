
import 'package:iermes/iermes.dart';
import 'package:work_db/work_db.dart';

import 'caching_implementation/ermes_caching_repository.dart';
import 'caching_implementation/ermes_caching_service.dart';
import 'ermes_storage_and_caching_messages.dart';
import 'storage_implementation/ermes_storage_repository.dart';

typedef ErmesStorageAndCachingMessageRoot
    = ErmesStorageAndCachingMessages<MessageRootStorage>;

typedef ErmesStorageAndCachingMessageType
    = ErmesStorageAndCachingMessages<MessageType>;

typedef ErmesStorageAndCachingMessagesHandlerBaseMessageRoot
    = ErmesStorageAndCachingMessagesHandlerBase<MessageRootStorage>;

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

  static ErmesStorageAndCachingMessagesHandler get instance => _instance;
}

/// Storage instance for a single peer
class PeerStorageInstance implements IPeerStorageInstance {
  PeerStorageInstance(this.peerId)
      : messageRoot = ErmesStorageAndCachingMessageRoot(
          ErmesStorageRepository<MessageRootStorage>(
            WorkDb.io(),
            'ermes_messages_root_$peerId',
          ),
          ErmesCachingService<MessageRootStorage>(
            ErmesCachingRepository<MessageRootStorage>(100),
          ),
        ),
        messageType = ErmesStorageAndCachingMessageType(
          ErmesStorageRepository<MessageType>(
            WorkDb.io(),
            'ermes_messages_type_$peerId',
          ),
          ErmesCachingService<MessageType>(
            ErmesCachingRepository<MessageType>(100),
          ),
        );

  @override
  final IdAccountType peerId;
  @override
  final ErmesStorageAndCachingMessageRoot messageRoot;
  @override
  final ErmesStorageAndCachingMessageType messageType;
}
