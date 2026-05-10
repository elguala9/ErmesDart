
import 'dart:typed_data';

import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'exceptions.dart';


/// Core repository implementation for Ermes data transport

class ErmesRepository extends ShspInstance implements IErmesRepository {
  // non togliere extends, è essenziale

  /// Constructor that retrieves peer info from book service
  ErmesRepository({
    required IdAccountType remotePeerId,
    required IShspSocket socket,
    required IErmesSignalingHandler<ShspPeer> signalHandler,
    required IErmesBookService<Object> ermesBookService,
    int timeoutMs = 30000,
  }) : this._(
    remotePeer: ermesBookService.getPeerInfo(remotePeerId) ??
        (throw CoreException('Peer info not found for account $remotePeerId')),
    socket: socket,
    remotePeerId: remotePeerId,
    signalHandler: signalHandler,
    timeoutMs: timeoutMs,
  );

  // Private constructor - use factory instead
  ErmesRepository._({
    required ErmesPeerInfo remotePeer,
    required super.socket,
    required this.remotePeerId,
    required this.signalHandler,
    this.timeoutMs = 30000,
  }) : super(remotePeer: remotePeer) {
    // Respond to the peer's incoming handshake automatically (SHSP protocol).
    // The response is sent only once to avoid feedback loops.
    var handshakeResponseSent = false;
    onHandshake.register((_) {
      if (!handshakeResponseSent) {
        handshakeResponseSent = true;
        sendHandshake();
      }
    });
    // Initiate SHSP handshake immediately after construction.
    sendHandshake();
  }

  @override
  final IdAccountType remotePeerId;
  final IErmesSignalingHandler<ShspPeer> signalHandler;
  final int timeoutMs;

  // Callback handlers for multiple listeners
  late final CallbackHandler<SerializableDataType, void> _onMessageHandler =
      CallbackHandler<SerializableDataType, void>();
  late final CallbackHandler<SerializableDataType, void> _onDataSendingHandler =
      CallbackHandler<SerializableDataType, void>();
  late final CallbackHandler<SerializableDataType, void> _onDataSentHandler =
      CallbackHandler<SerializableDataType, void>();

  @override
  void send(SerializableDataType data) {
    if (isClosed()) {
      throw StateError('Cannot send on closed connection');
    }

    // Invoke all pre-send listeners
    _onDataSendingHandler.call(data);

    // Use inherited ShspPeer's send method
    // ShspInstance.sendMessage mutates the list (inserts a prefix byte),
    // so we must pass a mutable copy since Uint8List is fixed-length.
    sendMessage(List<int>.from(data));

    // Invoke all post-send listeners
    _onDataSentHandler.call(data);
  }

  /// Override onMessage to route incoming data messages to registered
  /// listeners.
  ///
  /// ShspInstance.onMessage handles protocol messages (handshake, close, etc.)
  /// but ShspPeer.onMessage only fires PeerInfo-only callbacks, discarding the
  /// message payload. This override intercepts data messages (prefix 0x00) and
  /// calls _onMessageHandler with the actual payload bytes.
  @override
  void onMessage(List<int> msg, PeerInfo info) {
    // Let ShspInstance handle all protocol messages
    // (handshake, close, keep-alive, data)
    super.onMessage(msg, info);

    // For data messages (0x00 prefix), fire our data listeners
    // with the payload.
    // The payload is everything after the 0x00 prefix byte.
    if (msg.isNotEmpty && msg[0] == 0x00) {
      _onMessageHandler.call(Uint8List.fromList(msg.sublist(1)));
    }
  }

  @override
  void addOnMessageDataListener(CallbackOnDataRepository callback) {
    _onMessageHandler.register(callback);
  }

  @override
  void removeOnMessageDataListener(CallbackOnDataRepository callback) {
    _onMessageHandler.unregister(callback);
  }

  @override
  void clearOnMessageDataListeners() {
    _onMessageHandler.clear();
  }

  @override
  void destroy({bool force = false}) {
    super.close();
    // Clear all callback handlers
    _onMessageHandler.clear();
    _onDataSendingHandler.clear();
    _onDataSentHandler.clear();
  }
  
  @override
  bool isClosed() => !super.openState;

  @override
  bool isClosing() => super.closingState;

  @override
  bool isOpen() => super.openState;
  

}
