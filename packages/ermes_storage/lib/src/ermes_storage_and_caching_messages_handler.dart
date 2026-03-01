
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

/// Singleton handler for managing ErmesStorageAndCachingMessages instances per peer
class ErmesStorageAndCachingMessagesHandler {
  ErmesStorageAndCachingMessagesHandler._();

  static final _instance = ErmesStorageAndCachingMessagesHandler._();

  static ErmesStorageAndCachingMessagesHandler get instance => _instance;

  /// Map of peer storage instances keyed by IdAccountType
  final Map<IdAccountType, _PeerStorageInstance> _peerInstances = {};

  /// Get or create storage instance for a specific peer
  _PeerStorageInstance forPeer(IdAccountType peerId) {
    return _peerInstances.putIfAbsent(
      peerId,
      () => _PeerStorageInstance(peerId),
    );
  }

  /// Mapping of storage instances keyed by connection ID only
  final Map<IdConnectionType, ErmesStorageAndCachingMessages>
      _storageInstances = {};

  /// Get or retrieve a storage instance for the given connection
  ErmesStorageAndCachingMessages? get(
    IdConnectionType idConnectionType,
  ) =>
      _storageInstances[idConnectionType];
}

/// Storage instance for a single peer
class _PeerStorageInstance {
  _PeerStorageInstance(this.peerId)
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

  final IdAccountType peerId;
  final ErmesStorageAndCachingMessageRoot messageRoot;
  final ErmesStorageAndCachingMessageType messageType;
}
