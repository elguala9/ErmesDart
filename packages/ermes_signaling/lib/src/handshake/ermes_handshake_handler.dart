import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import '../../ermes_signaling.dart';

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
class ErmesHandshakeHandler
    implements IErmesHandshakeHandler<ErmesAsyncHandshakeInput, SignalErmes> {
  ErmesHandshakeHandler(this._localInfo);

  ErmesAsyncHandshakeInput _localInfo;

  @override
  void setLocalInfo(ErmesAsyncHandshakeInput info) {
    _localInfo = info;
  }

  @override
  IErmesHandshake<ErmesAsyncHandshakeInput, SignalErmes> newHandshake(
    SignalErmes info,
  ) => ErmesAsyncHandshake(_localInfo);
}
