// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations
import 'package:singleton_manager/singleton_manager.dart';
import '../key_exchange/ermes_peer_key_exchange.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';
import '../../ermes_cipher.dart';
import '../factories/ermes_cipher_factories.dart';

class ErmesPeerKeyExchangeDI extends ErmesPeerKeyExchange implements ISingletonStandardDI {

  ErmesPeerKeyExchangeDI() : super();

  factory ErmesPeerKeyExchangeDI.initializeDI() {
    final instance = ErmesPeerKeyExchangeDI();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
    peerCipher = SingletonDIAccess.get<IErmesPeerCipher>();
  }
}
