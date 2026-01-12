import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import 'i_ermes_handshake.dart';

@includeInBarrelFile
abstract class IErmesHandshakeHandler<LocalHandshakeInfo, RemoteHandshakeInfo> {
  IErmesHandshake<LocalHandshakeInfo, RemoteHandshakeInfo> newHandshake(
    RemoteHandshakeInfo info,
  );

  void setLocalInfo(LocalHandshakeInfo info);
}
