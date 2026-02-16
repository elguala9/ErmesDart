import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../../../iermes.dart';

@includeInBarrelFile
// ignore: one_member_abstracts
abstract class IErmesHandshake<LocalHandshakeInfo, RemoteHandshakeInfo> {
  IErmesRepository handshake();
}
