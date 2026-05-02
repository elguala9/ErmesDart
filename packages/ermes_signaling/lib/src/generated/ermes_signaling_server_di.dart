// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations
import 'package:singleton_manager/singleton_manager.dart';
import '../ermes_signaling_server.dart';
import 'package:iermes/iermes.dart';
import 'package:nostr_signaling/nostr_signaling.dart';

class ErmesSignalingServerDI extends ErmesSignalingServer implements ISingletonStandardDI {

  ErmesSignalingServerDI() : super.emptyForDI();

  factory ErmesSignalingServerDI.initializeDI() {
    final instance = ErmesSignalingServerDI();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
    nostrSignaling = SingletonDIAccess.get<INostrSignaling>();
    accountId = SingletonDIAccess.get<IdAccountType>();
  }
}
