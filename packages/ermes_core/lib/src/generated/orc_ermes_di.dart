// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations
import 'package:singleton_manager/singleton_manager.dart';
import '../orc_ermes.dart';
import 'dart:io';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';
import '../ermes_connections_handler.dart';
import '../ermes_peer.dart';
import '../factories/ermes_connections_handler_factory.dart';
import '../factories/ermes_peer_factory.dart';

class OrcErmesDI extends OrcErmes implements ISingletonStandardDI {

  OrcErmesDI() : super.emptyForDI();

  factory OrcErmesDI.initializeDI() {
    final instance = OrcErmesDI();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
    signalingServer = SingletonDIAccess.get<IErmesSignalingServer>();
    signalingHandler = SingletonDIAccess.get<IErmesSignalingHandler<ShspPeer>>();
    socket = SingletonDIAccess.get<IShspSocket>();
    bookService = SingletonDIAccess.get<IErmesBookService<BookData>>();
    connectionsHandler = SingletonDIAccess.get<ErmesConnectionsHandler>();
  }
}
