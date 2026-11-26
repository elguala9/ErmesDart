import 'dart:typed_data';

import 'package:iermes/iermes.dart';
import 'package:uuid/uuid.dart';

import '../serialization/ermes_send_root_builder.dart';
import '../serialization/ermes_serialization_utils.dart';
import '../support/storage_singletons.dart';
import '../utility/utility.dart';
import 'ermes_datagram_sizer.dart';
import 'ermes_retransmission_retention.dart';
import 'ermes_send_repo_callbacks.dart';

export '../serialization/ermes_serialization_utils.dart' show objectToUint8Array;

/// ErmesSendRepo - serializes, fragments, id-stamps and dispatches messages,
/// keeping each sent envelope's exact bytes for retransmission (RFC 9.5).
/// Chunk size is measured per send by [ErmesDatagramSizer] so datagrams stay
/// within [ermesMaxDatagramBytes]. See `docs/flows/message_lifecycle.md`.
class ErmesSendRepo {
  /// Binds a transport and id handler; throws if [maxByte] is too large.
  ErmesSendRepo(this._repository, this._idHandler, [int maxByte = 1024])
    : _sizer = ErmesDatagramSizer(
        (maxByte + maxHeader - 300).clamp(1, ermesMaxDatagramBytes),
      ) {
    if (maxByte >= 1200) {
      throw ArgumentError('Max byte cannot be more than 1299');
    }
    storageRoot = getErmesStorageAndCachingMessagesHandlerBaseMessageRoot()
        .forPeer(_repository.cipherKey)
        .messageRoot;
    retention = ErmesRetransmissionRetention(storage: storageRoot);
  }

  /// Persisted sent envelopes for retransmission.
  late IErmesStorageAndCachingMessages<MessageRootStorage> storageRoot;
  /// RFC 10.2 eviction (ack + retention window) over [storageRoot].
  late ErmesRetransmissionRetention retention;

  final IErmesRepository _repository; // transport
  final ErmesDatagramSizer _sizer; // chunk size keeping datagrams under cap
  final IIdHandlerService _idHandler; // assigns outgoing ids
  final ErmesSendRepoCallbacks _callbacks = ErmesSendRepoCallbacks();
  final Uuid _uuid = const Uuid(); // chunk reference ids
  /// Version negotiation gating sends and stamping `v`; null disables it.
  IErmesVersionNegotiation? versionNegotiation;
  /// Ids queued in [sendMessageType] but not yet stored (still available).
  final Set<int> _inFlight = {};
  final Map<int, Uint8List> _pending = {}; // on the wire, not yet persisted

  void addOnMessageSendingListener(CallbackOnMessageSending callback) =>
      _callbacks.addOnSending(callback);
  void removeOnMessageSendingListener(CallbackOnMessageSending callback) =>
      _callbacks.removeOnSending(callback);
  void clearOnMessageSendingListeners() => _callbacks.clearOnSending();
  void addOnMessageSentListener(CallbackOnMessageSent callback) =>
      _callbacks.addOnSent(callback);
  void removeOnMessageSentListener(CallbackOnMessageSent callback) =>
      _callbacks.removeOnSent(callback);
  void clearOnMessageSentListeners() => _callbacks.clearOnSent();

  /// Always null; setters register listeners.
  CallbackOnMessageSending? get callbackOnDataSending => null;
  set callbackOnDataSending(CallbackOnMessageSending callback) =>
      addOnMessageSendingListener(callback);
  CallbackOnMessageSent? get callbackOnDataSended => null;
  set callbackOnDataSended(CallbackOnMessageSent callback) =>
      addOnMessageSentListener(callback);

  /// Send user data, fragmenting if it exceeds the measured chunk size.
  Future<void> send(TypeOfData rawData) async {
    final chunkSize =
        _sizer.chunkSizeFor(_repository.cipherKey, rawData.length);
    if (rawData.length > chunkSize) {
      final chunkedId = _uuid.v4();
      final rawDataArray =
          chunkArrayBuffer(_idHandler, rawData, chunkedId, chunkSize);
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
    _inFlight.addAll(array.map((e) => e.id));
    final roots = buildMessageRoots(array, _repository.cipherKey);
    for (final (i, element) in array.indexed) {
      final gate = versionNegotiation;
      if (gate != null && !await gate.admitOutbound(element)) {
        _inFlight.remove(element.id);
        continue; // negotiation failed: nothing may leave (RFC 7.1)
      }
      _callbacks.notifySending(element);
      await _storeAndSend(roots[i], element.id);
      _inFlight.remove(element.id);
      _callbacks.notifySent(element);
    }
  }

  /// Serializes [root] once, sends and persists those bytes under [id];
  /// [_pending] keeps [id] resendable from the moment it is on the wire.
  Future<void> _storeAndSend(MessageRoot root, IdType id) async {
    final bytes =
        envelopeToUint8Array(root, versionNegotiation?.envelopeVersion);
    ensureDatagramFits(bytes);
    _pending[id] = bytes;
    try {
      _repository.send(bytes);
      await retention.store(
        MessageRootStorage.fromMessageRoot(root, id, envelope: bytes),
      );
    } finally {
      _pending.remove(id);
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }

  /// Resends the original envelope bit-for-bit (RFC 9.5); false when neither
  /// stored nor still queued, so the caller can answer `gone` (RFC 10.2).
  Future<bool> sendAgain(int idMessage) async {
    final stored = _pending.containsKey(idMessage)
        ? null
        : await retention.retrieve(idMessage);
    final bytes = _pending[idMessage] ??
        (stored == null
            ? null
            : storedEnvelopeBytes(stored, versionNegotiation?.envelopeVersion));
    if (bytes == null) {
      return _inFlight.contains(idMessage);
    }
    ensureDatagramFits(bytes);
    await _sendBytes(bytes);
    return true;
  }

  /// Dispatches [rawData], then yields 1 ms so the OS can flush the UDP
  /// socket buffer on large fragmented messages.
  Future<void> _sendBytes(Uint8List rawData) async {
    _repository.send(rawData);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}
