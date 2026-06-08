import 'dart:async';

import 'package:iermes/iermes.dart';

import 'ermes_message_decoder.dart';
import 'ermes_read_repo_listeners.dart';
import 'ermes_read_repo_options.dart';
import 'ermes_utility/chunk_handler.dart';
import 'ermes_utility/observable_queue.dart';
import 'exceptions.dart';
import 'serialization_helpers.dart';
import 'storage_singletons.dart';

export 'ermes_read_repo_options.dart';
export 'serialization_helpers.dart'
    show uint8ArrayToArrayBuffer, uint8ArrayToObject;

/// Handles message reception, decoding, chunk reassembly and the
/// reactive missing-message control hook.
///
/// Assembly flow: inbound bytes are decoded and deduplicated by integrity
/// hash, deserialized, reported to message-control, then routed by type —
/// service messages to listeners, data messages onto the not-read queue, and
/// chunks to a per-`refId` [ChunkHandler] that reassembles them in order once
/// all `roof` pieces arrive. Full walkthrough: `docs/flows/message_lifecycle.md`.
class ErmesReadRepo with ErmesReadRepoListeners {
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

  final ObservableQueue<TypeOfData> _messageNotReaded;
  final Set<String> _processedHashes = {};
  final Map<IdChunkType, ChunkHandler> _messageNotMerged = {};
  late IErmesStorageAndCachingMessages<MessageType> storageMessageType;

  final IErmesRepository _repository;
  final IErmesMessageControlService? ermesMessageControlService;
  final Future<void> Function()? _callbackOnMessageProcessed;
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

  void _pushInNotReaded(TypeOfData data) {
    if (_messageNotReaded.isFull) {
      return;
    }
    _messageNotReaded.push(data);
  }
}
