import 'dart:async';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:shsp_implementations/shsp_implementations.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:iermes/iermes.dart';
import 'package:ermes_types/ermes_types.dart';


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
  // ignore: unused_field
  CallbackOnDataRepository? _onMessageCallback;
  CallbackOnDataSending? _onDataSendingCallback;
  CallbackOnDataSent? _onDataSentCallback;


  

  @override
  void send(SerializableDataType data) {
    if (isClosed()) {
      throw StateError('Cannot send on closed connection');
    }



    try {
      _onDataSendingCallback?.call(data);

      // Use inherited ShspPeer's send method
      sendMessage(data);

      _onDataSentCallback?.call(data);
    } catch (e) {
      throw Exception('Failed to send data: $e');
    }
  }

  @override
  void onMessageData(CallbackOnDataRepository callback) {
    _onMessageCallback = callback;
    // Set up listener through inherited ShspPeer
  }


  @override
  void destroy({bool force = false}) {
    super.close();
    // Clear callbacks
    _onMessageCallback = null;
    _onDataSendingCallback = null;
    _onDataSentCallback = null;
  }
  
  @override
  bool isClosed() => !super.open;
  
  @override
  bool isClosing() => super.closing;
  @override
  bool isOpen() => super.open;
  

}
