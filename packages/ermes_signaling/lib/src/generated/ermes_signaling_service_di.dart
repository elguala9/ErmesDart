// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations
import 'package:singleton_manager/singleton_manager.dart';
import '../ermes_signaling_service.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

class ErmesSignalingServiceDI extends ErmesSignalingService implements ISingletonStandardDI {

  ErmesSignalingServiceDI() : super.emptyForDI();

  factory ErmesSignalingServiceDI.initializeDI() {
    final instance = ErmesSignalingServiceDI();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
    repo = SingletonDIAccess.get<IErmesSignalingRepository<ISignalErmes>>();
  }
}
