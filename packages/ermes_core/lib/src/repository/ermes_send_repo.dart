import 'package:iermes/iermes.dart';
import 'package:uuid/uuid.dart';

import '../serialization/ermes_send_root_builder.dart';
import '../serialization/ermes_serialization_utils.dart';
import '../support/storage_singletons.dart';
import '../utility/utility.dart';
import 'ermes_datagram_sizer.dart';
import 'ermes_send_repo_callbacks.dart';

export '../serialization/ermes_serialization_utils.dart' show objectToUint8Array;

/// ErmesSendRepo - Handles message sending and serialization.
///
/// Responsibilities: serialization, fragmentation for large messages,
/// integrity hashing, unique-ID assignment via IdHandler, dispatch via
/// the transport repository and notification of send listeners.
///
/// Fragmentation pipeline (see `send`): data larger than the chunk size is
/// split by [chunkArrayBuffer] into [ChunkMessage]s sharing a UUID `refId`.
/// The chunk size is measured per send by [ErmesDatagramSizer] against the
/// peer's current cipher state, so every serialized datagram stays within
/// [ermesMaxDatagramBytes]; [ensureDatagramFits] rejects anything larger.
/// Full walkthrough: `docs/flows/message_lifecycle.md`.
class ErmesSendRepo {
  /// Creates a send repository bound to a transport repository and id handler,
  /// with an optional maximum payload size; throws if [maxByte] is too large.
  ErmesSendRepo(this._repository, this._idHandler, [int maxByte = 1024])
    : _sizer = ErmesDatagramSizer(
        (maxByte + maxHeader - 300).clamp(1, ermesMaxDatagramBytes),
      ) {
    if (maxByte >= 1200) {
      throw ArgumentError('Max byte cannot be more than 1299');
    }
    storageRoot = getErmesStorageAndCachingMessagesHandlerBaseMessageRoot()
        .forPeer(_repository.remotePeerId)
        .messageRoot;
  }

  /// Storage handler persisting sent message roots for retransmission.
  late IErmesStorageAndCachingMessages<MessageRootStorage> storageRoot;

  /// Transport repository used to dispatch serialized messages.
  final IErmesRepository _repository;
  /// Measures the raw chunk size that keeps datagrams under the cap.
  final ErmesDatagramSizer _sizer;
  /// Handler assigning unique ids to outgoing messages.
  final IIdHandlerService _idHandler;
  /// Pre-send and post-send callback registries.
  final ErmesSendRepoCallbacks _callbacks = ErmesSendRepoCallbacks();
  final Uuid _uuid = const Uuid(); // chunk reference ids
  /// Version negotiation gating sends and stamping `v`; null disables it.
  IErmesVersionNegotiation? versionNegotiation;
  /// Ids queued in [sendMessageType] but not yet stored (still available).
  final Set<int> _inFlight = {};

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
  set callbackOnDataSending(CallbackOnMessageSending callback) =>
      addOnMessageSendingListener(callback);
  /// Always returns null; setter registers a post-send listener.
  CallbackOnMessageSent? get callbackOnDataSended => null;
  set callbackOnDataSended(CallbackOnMessageSent callback) =>
      addOnMessageSentListener(callback);

  /// Send user data, fragmenting if it exceeds the measured chunk size.
  Future<void> send(TypeOfData rawData) async {
    final chunkSize =
        _sizer.chunkSizeFor(_repository.cipherKey, rawData.length);
    if (rawData.length > chunkSize) {
      final chunkedId = _uuid.v4();
      final rawDataArray = chunkArrayBuffer(
        _idHandler,
        rawData,
        chunkedId,
        chunkSize,
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
    _inFlight.addAll(array.map((e) => e.id));
    final roots = buildMessageRoots(array, _repository.cipherKey);
    for (final (i, element) in array.indexed) {
      final gate = versionNegotiation;
      if (gate != null && !await gate.admitOutbound(element)) {
        _inFlight.remove(element.id);
        continue; // negotiation failed: nothing may leave (RFC 7.1)
      }
      _callbacks.notifySending(element);
      await _sendRootMessage(roots[i]);
      await storageRoot.store(
        MessageRootStorage.fromMessageRoot(roots[i], element.id),
      );
      _inFlight.remove(element.id);
      _callbacks.notifySent(element);
    }
  }

  /// Retransmits a stored root by id; false when neither stored nor still
  /// queued, so the caller can answer `gone` (RFC section 10.2).
  Future<bool> sendAgain(int idMessage) async {
    final rootMessage = await storageRoot.retrieve(idMessage);
    if (rootMessage == null) {
      return _inFlight.contains(idMessage);
    }
    await _sendRootMessage(rootMessage);
    return true;
  }

  /// Serialize and dispatch a [MessageRoot] via the transport repository.
  ///
  /// Yields to the event loop after sending so the OS can flush the UDP
  /// socket buffer, preventing overflow on large fragmented messages.
  Future<void> _sendRootMessage(MessageRoot message) async {
    final rawData =
        envelopeToUint8Array(message, versionNegotiation?.envelopeVersion);
    ensureDatagramFits(rawData);
    _repository.send(rawData);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}
