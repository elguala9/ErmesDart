import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import '../ermes_message_control.dart';
import 'generated/ermes_message_control_service_di.dart';

void initalPointMessageControl(){
  final repo = ErmesMessageControlFactory.createRepository();
  SingletonDIAccess.addInstanceAs<IErmesMessageControlRepository, ErmesMessageControlRepository>(repo);
  final service = ErmesMessageControlServiceDI.initializeDI();
  SingletonDIAccess.addInstanceAs<IErmesMessageControlService, ErmesMessageControlServiceDI>(service);
}

IErmesMessageControlService getIErmesMessageControlService() => SingletonDIAccess.get<IErmesMessageControlService>();
