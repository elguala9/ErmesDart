import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:callback_handler/callback_handler.dart';
import 'package:shsp_implementations/shsp_implementations.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:iermes/iermes.dart';


/// Core repository implementation for Ermes data transport
@includeInBarrelFile
class ErmesRepository extends ShspInstance implements IErmesRepository {
  // non togliere extends, è essenziale
  ErmesRepository({
    required super.remotePeer,
    required super.socket,
    required this.remotePeerId,
    required this.signalHandler,
    this.timeoutMs = 30000,
  });

  final IdAccountType remotePeerId;
  final IErmesSignalingHandler<IShspSocket> signalHandler;
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

    try {
      // Invoke all pre-send listeners
      _onDataSendingHandler.call(data);

      // Use inherited ShspPeer's send method
      sendMessage(data);

      // Invoke all post-send listeners
      _onDataSentHandler.call(data);
    } catch (e) {
      throw Exception('Failed to send data: $e');
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
  bool isClosed() => !super.open;
  
  @override
  bool isClosing() => super.closing;
  @override
  bool isOpen() => super.open;
  

}
