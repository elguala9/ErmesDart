// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations
import 'package:singleton_manager/singleton_manager.dart';
import '../storage/id_handler_storage_service.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:work_db/work_db.dart';
import '../../ermes_id_handler.dart';

class IdHandlerStorageServiceDI extends IdHandlerStorageService implements ISingletonStandardDI {

  IdHandlerStorageServiceDI() : super();

  factory IdHandlerStorageServiceDI.initializeDI() {
    final instance = IdHandlerStorageServiceDI();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
    repo = SingletonDIAccess.get<IIdHandlerStorageRepository>();
  }
}
