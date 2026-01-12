import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../../../iermes.dart';

@includeInBarrelFile
abstract class IErmesHandshake<LocalHandshakeInfo, RemoteHandshakeInfo> {
  IErmesRepository handshake();
}
