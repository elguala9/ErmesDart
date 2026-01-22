import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';
import 'package:shsp_implementations/shsp_implementations.dart';

/// Implementazione concreta di IErmesSignalingHandler
/// This class should be used by IErmesSignalingRepository. It handles the creation and processing of signaling messages
@includeInBarrelFile
class ErmesSignalingHandler implements IErmesSignalingHandler<ShspSocket> {
  ErmesSignalingHandler(IErmesSignalingService signalingService) {
    _signalingService = signalingService;
  }

  late IErmesSignalingService _signalingService; 

  @override
  Future<void> clearConnection(IdAccountType remotePeerId) {
    // TODO: implement clearConnection
    throw UnimplementedError();
  }

  @override
  Future<ISignalErmes> createSignal([IdAccountType? remotePeerId]) {
    _signalingService
  }

  @override
  Future<void> destroy() {
    // TODO: implement destroy
    throw UnimplementedError();
  }

  @override
  Future<List<IdAccountType>> getAllPeerIds() {
    // TODO: implement getAllPeerIds
    throw UnimplementedError();
  }

  @override
  Future<SocketDto<ShspSocket>> getSocket(IdAccountType of) {
    // TODO: implement getSocket
    throw UnimplementedError();
  }

  @override
  Future<bool> isSocketReady(IdAccountType of) {
    // TODO: implement isSocketReady
    throw UnimplementedError();
  }

  @override
  Future<void> onSocketReady(
    IdAccountType from,
    SocketReadyCallback<SocketDto<ShspSocket>> callback,
  ) {
    // TODO: implement onSocketReady
    throw UnimplementedError();
  }

  @override
  Future<void> processSignal(ISignalErmes signal, IdAccountType from) {
    // TODO: implement processSignal
    throw UnimplementedError();
  }

  @override
  Future<void> softClearConnection(IdAccountType remotePeerId) {
    // TODO: implement softClearConnection
    throw UnimplementedError();
  }

  @override
  Future<SocketDto<ShspSocket>> waitForConnect(IdAccountType peerId, int ms) {
    // TODO: implement waitForConnect
    throw UnimplementedError();
  }
}
