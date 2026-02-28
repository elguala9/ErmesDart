

import 'i_ermes_handshake.dart';

abstract class IErmesHandshakeHandler<LocalHandshakeInfo, RemoteHandshakeInfo> {
  IErmesHandshake<LocalHandshakeInfo, RemoteHandshakeInfo> newHandshake(
    RemoteHandshakeInfo info,
  );

  void setLocalInfo(LocalHandshakeInfo info);
}
