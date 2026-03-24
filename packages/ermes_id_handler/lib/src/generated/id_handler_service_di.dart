// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations
import 'package:singleton_manager/singleton_manager.dart';
import '../handlers/id_handler_service.dart';
import 'package:iermes/iermes.dart';
import '../../ermes_id_handler.dart';

class IdHandlerServiceDI extends IdHandlerService implements ISingletonStandardDI {

  IdHandlerServiceDI() : super();

  factory IdHandlerServiceDI.initializeDI() {
    final instance = IdHandlerServiceDI();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
    repo = SingletonDIAccess.get<IIdHandlerRepository>();
    storage = SingletonDIAccess.get<IIdHandlerStorageService>();
  }
}
