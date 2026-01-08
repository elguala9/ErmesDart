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
    implements IErmesAsyncHandshake<ErmesAsyncHandshakeInput, SignalErmes> {
  ErmesAsyncHandshake(this._localInfo);

  ErmesAsyncHandshakeInput _localInfo;

  @override
  void setLocalInfo(ErmesAsyncHandshakeInput info) {
    _localInfo = info;
  }

  @override
  IErmesService asyncHandshake(SignalErmes info) {
    // TODO: Implement async handshake
    // This should:
    // 1. Use the remote handshake info to establish connection
    // 2. Create and return an IErmesService instance
    // 3. Handle the signaling/connection establishment
    throw UnimplementedError('asyncHandshake not yet implemented');
  }
}
