import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import '../../ermes_signaling.dart';
import '../ermes_signal_type.dart';

typedef ErmesAsyncHandshakeInput = ({
  String publicKey,
  String privateKey,
  String curve,
});

/// Implementation of async handshake for establishing peer connections
///
/// This class manages the handshake process for creating connections between
/// peers using signaling and service creation.
@includeInBarrelFile
class ErmesAsyncHandshake
    implements IErmesHandshake<ErmesAsyncHandshakeInput, SignalErmes> {
  ErmesAsyncHandshake(this._localInfo);

  // ignore: unused_field
  final ErmesAsyncHandshakeInput _localInfo;

  @override
  IErmesRepository handshake() {
    // TODO: implement handshake
    throw UnimplementedError();
  }
}
