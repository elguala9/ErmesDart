import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:work_db/work_db.dart';

void initialPointIdHanlder(){
  const input = IoWorkDbFactoryInput(dataPath: './id_handler');
  final db = WorkDbFactory().create(input);
  final repoStorage =
      IdHandlerStorageRepositoryDI.initializeWithParametersDI(db);
  SingletonDIAccess.addInstanceAs<
      IIdHandlerStorageRepository,
      IdHandlerStorageRepositoryDI>(repoStorage);
  final serviceStorage = IdHandlerStorageServiceDI.initializeDI();
  SingletonDIAccess.addInstanceAs<
      IIdHandlerStorageService,
      IdHandlerStorageServiceDI>(serviceStorage);
  final repo = IdHandlerRepository();
  SingletonDIAccess.addInstanceAs<
      IIdHandlerRepository, IdHandlerRepository>(repo);
  final service = IdHandlerServiceDI.initializeDI();
  SingletonDIAccess.addInstanceAs<
      IIdHandlerService, IdHandlerServiceDI>(service);
}
