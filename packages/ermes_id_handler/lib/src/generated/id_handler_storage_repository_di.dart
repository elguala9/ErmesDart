// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations
import 'package:singleton_manager/singleton_manager.dart';
import '../storage/id_handler_storage_repository.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:work_db/work_db.dart';

class IdHandlerStorageRepositoryDI extends IdHandlerStorageRepository implements ISingletonStandardDI {

  IdHandlerStorageRepositoryDI() : super();

  factory IdHandlerStorageRepositoryDI.initializeDI() {
    final instance = IdHandlerStorageRepositoryDI();
    instance.initializeDI();
    return instance;
  }

  factory IdHandlerStorageRepositoryDI.initializeWithParametersDI(IWorkDbSync db) {
    final instance = IdHandlerStorageRepositoryDI();
    instance.db = db;
    return instance;
  }

  @override
  void initializeDI() {
    db = SingletonDIAccess.get<IWorkDbSync>();
  }
}
