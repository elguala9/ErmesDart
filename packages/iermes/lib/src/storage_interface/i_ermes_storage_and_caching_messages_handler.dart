
import '../../iermes.dart';

abstract class IPeerStorageInstance {
  IdAccountType get peerId;
  IErmesStorageAndCachingMessages<MessageRootStorage> get messageRoot;
  IErmesStorageAndCachingMessages<MessageType> get messageType;
}

abstract class IErmesStorageAndCachingMessagesHandlerBase<DataJson> {
  IPeerStorageInstance forPeer(IdAccountType peerId);
  IErmesStorageAndCachingMessages<DataJson>? get(
      IdConnectionType idConnectionType);
}
