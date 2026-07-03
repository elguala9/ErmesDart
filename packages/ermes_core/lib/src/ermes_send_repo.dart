import 'package:iermes/iermes.dart';
import 'package:uuid/uuid.dart';

import 'ermes_send_repo_callbacks.dart';
import 'ermes_send_root_builder.dart';
import 'ermes_serialization_utils.dart';
import 'storage_singletons.dart';
import 'utility.dart';

export 'ermes_serialization_utils.dart' show objectToUint8Array;

/// ErmesSendRepo - Handles message sending and serialization.
///
/// Responsibilities: serialization, fragmentation for large messages,
/// integrity hashing, unique-ID assignment via IdHandler, dispatch via
/// the transport repository and notification of send listeners.
///
/// Fragmentation pipeline (see `send`): data larger than [_chunkDataSize] is
/// split by [chunkArrayBuffer] into `ceil(total / chunkDataSize)` [ChunkMessage]s
/// sharing a UUID `refId`; each carries its `index` and the total `roof` so the
/// receiver can detect completion and missing pieces. [_chunkDataSize] is
/// capped so each serialized datagram stays under a safe path MTU. Each message
/// is wrapped in a [MessageRoot] (integrity hash added), persisted for
/// retransmission and dispatched. Full walkthrough:
/// `docs/flows/message_lifecycle.md`.
class ErmesSendRepo {
  /// Creates a send repository bound to a transport repository and id handler,
  /// with an optional maximum payload size; throws if [maxByte] is too large.
  ErmesSendRepo(this._repository, this._idHandler, [int maxByte = 1024])
    : _chunkDataSize =
          (maxByte + maxHeader - 300).clamp(1, _mtuSafeChunkData) {
    if (maxByte >= 1200) {
      throw ArgumentError('Max byte cannot be more than 1299');
    }
    storageRoot = getErmesStorageAndCachingMessagesHandlerBaseMessageRoot()
        .forPeer(_repository.remotePeerId)
        .messageRoot;
  }

  /// Conservative per-datagram ceiling (bytes): below the IPv6 minimum MTU
  /// (1280) minus IP/UDP headers and slack, so a serialized datagram survives
  /// a constrained path MTU instead of being silently dropped.
  static const int _safeDatagramBytes = 1200;

  /// Fixed serialization overhead around one chunk's payload (MessageRoot
  /// keys, integrity hash, refId UUID, index/roof/id fields).
  static const int _wireEnvelopeOverhead = 320;

  /// Max raw payload bytes per datagram so the serialized result stays under
  /// [_safeDatagramBytes]: the payload is base64-encoded (×4/3), so invert
  /// that to size the raw data. Caps chunk size and the fragmentation
  /// threshold so no datagram exceeds a safe path MTU.
  static const int _mtuSafeChunkData =
      (_safeDatagramBytes - _wireEnvelopeOverhead) * 3 ~/ 4;

  /// Storage handler persisting sent message roots for retransmission.
  late IErmesStorageAndCachingMessages<MessageRootStorage> storageRoot;

  /// Transport repository used to dispatch serialized messages.
  final IErmesRepository _repository;
  /// Raw bytes carried per datagram: the smaller of the configured budget
  /// (`maxByte + maxHeader - 300`) and the MTU-safe ceiling. Used both as the
  /// chunk size and the threshold above which a message is fragmented.
  final int _chunkDataSize;
  /// Handler assigning unique ids to outgoing messages.
  final IIdHandlerService _idHandler;
  /// Pre-send and post-send callback registries.
  final ErmesSendRepoCallbacks _callbacks = ErmesSendRepoCallbacks();
  /// Generator for chunk reference ids.
  final Uuid _uuid = const Uuid();

  /// Registers a listener invoked before a message is sent.
  void addOnMessageSendingListener(CallbackOnMessageSending callback) =>
      _callbacks.addOnSending(callback);

  /// Unregisters a previously added pre-send listener.
  void removeOnMessageSendingListener(CallbackOnMessageSending callback) =>
      _callbacks.removeOnSending(callback);

  /// Removes all registered pre-send listeners.
  void clearOnMessageSendingListeners() => _callbacks.clearOnSending();

  /// Registers a listener invoked after a message has been sent.
  void addOnMessageSentListener(CallbackOnMessageSent callback) =>
      _callbacks.addOnSent(callback);

  /// Unregisters a previously added post-send listener.
  void removeOnMessageSentListener(CallbackOnMessageSent callback) =>
      _callbacks.removeOnSent(callback);

  /// Removes all registered post-send listeners.
  void clearOnMessageSentListeners() => _callbacks.clearOnSent();

  /// Always returns null; setter registers a pre-send listener.
  CallbackOnMessageSending? get callbackOnDataSending => null;
  /// Registers a pre-send listener via assignment.
  set callbackOnDataSending(CallbackOnMessageSending callback) {
    addOnMessageSendingListener(callback);
  }

  /// Always returns null; setter registers a post-send listener.
  CallbackOnMessageSent? get callbackOnDataSended => null;
  /// Registers a post-send listener via assignment.
  set callbackOnDataSended(CallbackOnMessageSent callback) {
    addOnMessageSentListener(callback);
  }

  /// Send user data, fragmenting if it exceeds [_chunkDataSize].
  Future<void> send(TypeOfData rawData) async {
    if (rawData.length > _chunkDataSize) {
      final chunkedId = _uuid.v4();
      final rawDataArray = chunkArrayBuffer(
        _idHandler,
        rawData,
        chunkedId,
        _chunkDataSize,
      );
      for (final chunk in rawDataArray) {
        _callbacks.notifySending(MessageType.chunk(chunk));
      }
      await sendMessageType(rawDataArray.map(MessageType.chunk).toList());
      return;
    }

    final newId = _idHandler.getNewId();
    final message = createMessageDataErmes(rawData, newId);
    _callbacks.notifySending(MessageType.data(message));
    await sendMessageType([MessageType.data(message)]);
  }

  /// Convert each [MessageType] to a [MessageRoot], persist and dispatch.
  Future<void> sendMessageType(List<MessageType> array) async {
    for (final element in array) {
      final messageRoot = buildMessageRoot(element, _repository.remotePeerId);
      _callbacks.notifySending(element);
      await _sendRootMessage(messageRoot);
      await storageRoot.store(
        MessageRootStorage.fromMessageRoot(messageRoot, element.id),
      );
      _callbacks.notifySent(element);
    }
  }

  /// Retransmits a previously stored message root by its id, if present.
  Future<void> sendAgain(int idMessage) async {
    final rootMessage = await storageRoot.retrieve(idMessage);
    if (rootMessage != null) {
      await _sendRootMessage(rootMessage);
    }
  }

  /// Serialize and dispatch a [MessageRoot] via the transport repository.
  ///
  /// Yields to the event loop after sending so the OS can flush the UDP
  /// socket buffer, preventing overflow on large fragmented messages.
  Future<void> _sendRootMessage(MessageRoot message) async {
    final rawData = objectToUint8Array(message);
    _repository.send(rawData);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}
