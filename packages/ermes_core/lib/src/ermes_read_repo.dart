import 'dart:async';

import 'package:callback_handler/callback_handler.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:iermes/iermes.dart';

import 'ermes_message_decoder.dart';
import 'ermes_utility/chunk_handler.dart';
import 'ermes_utility/observable_queue.dart';
import 'exceptions.dart';
import 'serialization_helpers.dart';

export 'serialization_helpers.dart'
    show uint8ArrayToArrayBuffer, uint8ArrayToObject;

/// Cache used to deduplicate incoming messages by their integrity hash.
typedef ErmesDeduplicationCache = IGenericCachingRepository<String, bool>;

/// Configuration for [ErmesReadRepo].
class ErmesReadRepoOptions {
  const ErmesReadRepoOptions({
    this.maxBufferSize,
    this.maxMessageSize,
    this.callbackOnDataArrived,
    this.callbackOnMessageProcessed,
  });

  final int? maxBufferSize;
  final int? maxMessageSize;
  final CallbackOnDataArrived? callbackOnDataArrived;
  final Future<void> Function()? callbackOnMessageProcessed;
}

/// Handles message reception, decoding, chunk reassembly and the
/// reactive missing-message control hook.
class ErmesReadRepo {
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
    _serviceMessageHandler.register(callbackServiceMessage);

    if (options.callbackOnDataArrived != null) {
      _onDataArrivedHandler.register(options.callbackOnDataArrived!);
    }

    _repository.addOnMessageDataListener(_handleMessageArrayBuffer);

    storageMessageType =
        getErmesStorageAndCachingMessagesHandlerBaseMessageType()
            .forPeer(_repository.remotePeerId)
            .messageType;

    _messageNotReaded.onAddCallback = () {
      while (!_messageNotReaded.isEmpty()) {
        _onDataArrivedHandler.call(_messageNotReaded.shift());
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

  late final CallbackHandler<ServiceMessage, void> _serviceMessageHandler =
      CallbackHandler<ServiceMessage, void>();
  late final CallbackHandler<TypeOfDataExternal, void> _onDataArrivedHandler =
      CallbackHandler<TypeOfDataExternal, void>();

  void addServiceMessageListener(CallbackServiceMessage cb) =>
      _serviceMessageHandler.register(cb);
  void removeServiceMessageListener(CallbackServiceMessage cb) =>
      _serviceMessageHandler.unregister(cb);

  void addOnDataArrivedListener(CallbackOnDataArrived cb) =>
      _onDataArrivedHandler.register(cb);
  void removeOnDataArrivedListener(CallbackOnDataArrived cb) =>
      _onDataArrivedHandler.unregister(cb);
  void clearOnDataArrivedListeners() => _onDataArrivedHandler.clear();

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
        _serviceMessageHandler.call(serviceMsg);
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
