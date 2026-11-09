import 'dart:async';

import 'package:iermes/iermes.dart';

import '../serialization/ermes_message_decoder.dart';
import '../serialization/serialization_helpers.dart';
import '../support/ermes_receive_stats.dart';
import '../support/storage_singletons.dart';
import '../utility/observable_queue.dart';
import 'ermes_envelope_version_gate.dart';
import 'ermes_read_repo_chunking.dart';
import 'ermes_read_repo_gone.dart';
import 'ermes_read_repo_listeners.dart';
import 'ermes_read_repo_options.dart';
import 'ermes_read_repo_routing.dart';

export '../serialization/serialization_helpers.dart'
    show uint8ArrayToArrayBuffer, uint8ArrayToObject;
export 'ermes_read_repo_options.dart';

/// Handles message reception, decoding, chunk reassembly and the
/// reactive missing-message control hook.
///
/// Inbound bytes are decoded, deduplicated by hash, then routed by type to
/// service listeners, the not-read queue or per-`refId` chunk reassembly
/// ([ErmesChunkGroups], which also applies a peer `gone`, RFC 7.3).
/// Full walkthrough: `docs/flows/message_lifecycle.md`.
class ErmesReadRepo with ErmesReadRepoListeners, ErmesReadRepoChunking {
  /// Creates a read repository, wiring up the service-message and data-arrived
  /// listeners, storage handler and the inbound message pipeline.
  ErmesReadRepo(
    this._repository,
    CallbackServiceMessage callbackServiceMessage,
    this.ermesMessageControlService,
    ErmesReadRepoOptions options,
  ) : _messageNotReaded = ObservableQueue<TypeOfData>(
        options.maxBufferSize ?? 100,
      ),
      _callbackOnMessageProcessed = options.callbackOnMessageProcessed,
      _negotiation = options.versionNegotiation,
      chunkGroups = ErmesChunkGroups(maxTotalSize: options.maxMessageSize) {
    addServiceMessageListener(callbackServiceMessage);

    if (options.callbackOnDataArrived != null) {
      addOnDataArrivedListener(options.callbackOnDataArrived!);
    }

    _repository.addOnMessageDataListener(_handleMessageArrayBuffer);

    storageMessageType =
        getErmesStorageAndCachingMessagesHandlerBaseMessageType()
            .forPeer(_repository.remotePeerId)
            .messageType;

    _messageNotReaded.onAddCallback = () {
      while (!_messageNotReaded.isEmpty()) {
        notifyDataArrived(_messageNotReaded.shift());
      }
    };
  }

  /// Buffer of received but not-yet-consumed data messages.
  final ObservableQueue<TypeOfData> _messageNotReaded;
  /// Integrity hashes of already-processed messages, used for deduplication.
  final Set<String> _processedHashes = {};
  /// Pending chunk reassembly groups keyed by reference id.
  @override
  final ErmesChunkGroups chunkGroups;
  /// Storage handler persisting messages for the remote peer.
  late IErmesStorageAndCachingMessages<MessageType> storageMessageType;

  /// Repository providing the inbound message stream.
  final IErmesRepository _repository;
  /// Optional message-control service tracking received message ids.
  @override
  final IErmesMessageControlService? ermesMessageControlService;
  /// Optional callback awaited after each data message is processed.
  final Future<void> Function()? _callbackOnMessageProcessed;
  /// Optional version negotiation gating inbound envelopes.
  final IErmesVersionNegotiation? _negotiation;

  /// Wire-format entry point: decodes, deduplicates, dispatches.
  Future<void> _handleMessageArrayBuffer(SerializableDataType message) async {
    final stats = ErmesReceiveStats.active?..onFrame();
    try {
      final decoded = decodeMessageEnvelope(
        message,
        _repository.cipherKey,
        _processedHashes,
        onUnsupportedVersion: _negotiation?.onUnsupportedEnvelope,
      );
      if (decoded == null) {
        stats?.onDecodeDropped();
        return;
      }
      final inner = uint8ArrayToObject<InternalMessage>(decoded.plainBytes);
      final gate = _negotiation;
      if (isWithinKeyBounds(decoded, _repository.cipherKey, inner) &&
          (gate == null || await admitEnvelope(gate, decoded.version, inner))) {
        await _handleMessageType(inner);
      }
    } on Object catch (e) {
      stats?.onFailed(e);
      rethrow;
    }
  }

  /// Records, stores and dispatches a deserialized message by its type.
  Future<void> _handleMessageType(InternalMessage mess) async {
    final messageType = mess.type;

    ermesMessageControlService?.idArrived(mess.message.getId());
    unawaited(storageMessageType.store(mess.message));

    if (messageType == MessageValue.service) {
      final serviceMsg = mess.message.asService();
      if (serviceMsg != null) {
        notifyServiceMessage(serviceMsg);
      }
      return;
    }

    routeDataMessage(mess.message, messageType);

    if (_callbackOnMessageProcessed != null) {
      await _callbackOnMessageProcessed();
    }
  }

  /// Enqueues data onto the not-read buffer unless the buffer is full.
  @override
  void pushInNotReaded(TypeOfData data) {
    if (_messageNotReaded.isFull) {
      ErmesReceiveStats.active?.onBufferFull();
      return;
    }
    _messageNotReaded.push(data);
  }
}
