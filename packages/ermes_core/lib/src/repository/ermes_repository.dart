
import 'dart:typed_data';

import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../support/exceptions.dart';


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

  /// Private constructor performing SHSP handshake setup; use the factory
  /// constructor or a dedicated factory instead.
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

  /// Identifier of the remote peer this repository communicates with.
  @override
  final IdAccountType remotePeerId;
  /// Signaling handler managing the underlying SHSP peer connection.
  final IErmesSignalingHandler<ShspPeer> signalHandler;
  /// Connection timeout in milliseconds.
  final int timeoutMs;

  // Callback handlers for multiple listeners
  /// Listeners notified when a data message is received.
  late final CallbackHandler<SerializableDataType, void> _onMessageHandler =
      CallbackHandler<SerializableDataType, void>();
  /// Listeners notified just before data is sent.
  late final CallbackHandler<SerializableDataType, void> _onDataSendingHandler =
      CallbackHandler<SerializableDataType, void>();
  /// Listeners notified just after data has been sent.
  late final CallbackHandler<SerializableDataType, void> _onDataSentHandler =
      CallbackHandler<SerializableDataType, void>();

  /// Sends data over the connection, firing pre- and post-send listeners;
  /// throws if the connection is closed.
  @override
  void send(SerializableDataType data) {
    if (isConnectionClosed) {
      throw CoreException('Cannot send on closed connection');
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

  /// Registers a listener invoked when a data message is received.
  @override
  void addOnMessageDataListener(CallbackOnDataRepository callback) {
    _onMessageHandler.register(callback);
  }

  /// Unregisters a previously added data-message listener.
  @override
  void removeOnMessageDataListener(CallbackOnDataRepository callback) {
    _onMessageHandler.unregister(callback);
  }

  /// Removes all registered data-message listeners.
  @override
  void clearOnMessageDataListeners() {
    _onMessageHandler.clear();
  }

  /// Closes the connection and clears all callback handlers.
  @override
  void destroy({bool force = false}) {
    super.close();
    // Clear all callback handlers
    _onMessageHandler.clear();
    _onDataSendingHandler.clear();
    _onDataSentHandler.clear();
  }
  
  /// Whether the connection is closed.
  @override
  bool get isConnectionClosed => !super.openState;

  /// Whether the connection is in the process of closing.
  @override
  bool isClosing() => super.closingState;

  /// Whether the connection is currently open.
  @override
  bool isOpen() => super.openState;
  

}
