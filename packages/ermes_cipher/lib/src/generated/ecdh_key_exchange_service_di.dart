// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations
import 'package:singleton_manager/singleton_manager.dart';
import '../key_exchange/ecdh_key_exchange_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptdart/cryptdart.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import '../factories/ermes_cipher_factories.dart';

class ECDHKeyExchangeServiceDI extends ECDHKeyExchangeService implements ISingletonStandardDI {

  ECDHKeyExchangeServiceDI() : super();

  factory ECDHKeyExchangeServiceDI.initializeDI() {
    final instance = ECDHKeyExchangeServiceDI();
    instance.initializeDI();
    return instance;
  }

  factory ECDHKeyExchangeServiceDI.initializeWithParametersDI(CryptoAlgorithm symmetricAlgorithm) {
    final instance = ECDHKeyExchangeServiceDI();
    instance.exchange = SingletonDIAccess.get<IKeyExchange>();
    instance.symmetricAlgorithm = symmetricAlgorithm;
    return instance;
  }

  @override
  void initializeDI() {
    exchange = SingletonDIAccess.get<IKeyExchange>();
    symmetricAlgorithm = SingletonDIAccess.get<CryptoAlgorithm>();
  }
}
