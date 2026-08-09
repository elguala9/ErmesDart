import 'dart:async';

import 'package:iermes/iermes.dart';

import '../serialization/ermes_message_decoder.dart';
import '../serialization/serialization_helpers.dart';
import '../support/exceptions.dart';
import '../support/storage_singletons.dart';
import '../utility/chunk_handler.dart';
import '../utility/observable_queue.dart';
import 'ermes_read_repo_listeners.dart';
import 'ermes_read_repo_options.dart';

export '../serialization/serialization_helpers.dart'
    show uint8ArrayToArrayBuffer, uint8ArrayToObject;
export 'ermes_read_repo_options.dart';

/// Handles message reception, decoding, chunk reassembly and the
/// reactive missing-message control hook.
///
/// Assembly flow: inbound bytes are decoded and deduplicated by integrity
/// hash, deserialized, reported to message-control, then routed by type —
/// service messages to listeners, data messages onto the not-read queue, and
/// chunks to a per-`refId` [ChunkHandler] that reassembles them in order once
/// all `roof` pieces arrive. Full walkthrough: `docs/flows/message_lifecycle.md`.
class ErmesReadRepo with ErmesReadRepoListeners {
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
      _maxMessageSize = options.maxMessageSize {
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
  /// Pending chunk reassembly handlers keyed by reference id.
  final Map<IdChunkType, ChunkHandler> _messageNotMerged = {};
  /// Storage handler persisting messages for the remote peer.
  late IErmesStorageAndCachingMessages<MessageType> storageMessageType;

  /// Repository providing the inbound message stream.
  final IErmesRepository _repository;
  /// Optional message-control service tracking received message ids.
  final IErmesMessageControlService? ermesMessageControlService;
  /// Optional callback awaited after each data message is processed.
  final Future<void> Function()? _callbackOnMessageProcessed;
  /// Maximum allowed reassembled message size, if enforced.
  final int? _maxMessageSize;

  /// Wire-format entry point: decodes, deduplicates, dispatches.
  Future<void> _handleMessageArrayBuffer(SerializableDataType message) async {
    final decoded = decodeMessageEnvelope(
      message,
      _repository.remotePeerId,
      _processedHashes,
    );
    if (decoded == null) {
      return;
    }

    final messageDeserialized =
        uint8ArrayToObject<InternalMessage>(decoded.plainBytes);
    await _handleMessageType(messageDeserialized);
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

    _routeDataMessage(mess.message, messageType);

    if (_callbackOnMessageProcessed != null) {
      await _callbackOnMessageProcessed();
    }
  }

  /// Routes a non-service message to the not-read queue or chunk reassembler.
  void _routeDataMessage(MessageType mess, MessageValue messageType) {
    switch (messageType) {
      case MessageValue.base:
        final dataMsg = mess.asData();
        if (dataMsg != null) {
          _pushInNotReaded(dataMsg.data);
        }
      case MessageValue.chunk:
        final chunkMsg = mess.asChunk();
        if (chunkMsg != null) {
          _handleChunkMessage(chunkMsg);
        }
      case MessageValue.service:
        throw CoreException('Message type not found: $messageType');
    }
  }

  /// Feeds a chunk into its reassembly handler, pushing the merged buffer when
  /// all pieces have arrived.
  void _handleChunkMessage(ChunkMessage mess) {
    final handler = _messageNotMerged.putIfAbsent(
      mess.refId,
      () => ChunkHandler(
        mess.refId,
        mess.roof,
        maxTotalSize: _maxMessageSize,
      ),
    );

    final buffer = handler.addChunk(mess);
    if (buffer != null) {
      _pushInNotReaded(buffer);
      _messageNotMerged.remove(mess.refId);
    }
  }

  /// Enqueues data onto the not-read buffer unless the buffer is full.
  void _pushInNotReaded(TypeOfData data) {
    if (_messageNotReaded.isFull) {
      return;
    }
    _messageNotReaded.push(data);
  }
}
