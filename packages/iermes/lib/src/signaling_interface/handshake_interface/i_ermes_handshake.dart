import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../../../iermes.dart';

@includeInBarrelFile
abstract class IErmesAsyncHandshake<LocalHandshakeInfo, RemoteHandshakeInfo> {
  IErmesService asyncHandshake(RemoteHandshakeInfo info);

  void setLocalInfo(LocalHandshakeInfo info);
}
