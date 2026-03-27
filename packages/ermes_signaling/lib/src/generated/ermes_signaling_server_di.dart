// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations
import 'package:singleton_manager/singleton_manager.dart';
import '../ermes_signaling_server.dart';
import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:signaling_contract_sdk/signaling_contract_extensions.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';
import '../ermes_signal_type.dart';

class ErmesSignalingServerDI extends ErmesSignalingServer implements ISingletonStandardDI {

  ErmesSignalingServerDI() : super.emptyForDI();

  factory ErmesSignalingServerDI.initializeDI() {
    final instance = ErmesSignalingServerDI();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
    contract = SingletonDIAccess.get<SignalingContract>();
    accountId = SingletonDIAccess.get<IdAccountType>();
  }
}
