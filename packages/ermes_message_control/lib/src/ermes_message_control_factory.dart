
import 'package:iermes/iermes.dart';

import 'ermes_message_control_repository.dart';
import 'ermes_message_control_service.dart';

/// 8️⃣ Factory per Message Control
/// Tradotto da: ErmesMessageControlFactory.ts

class ErmesMessageControlFactory {
  ErmesMessageControlFactory._();

  
  static ErmesMessageControlService createService(
    IErmesMessageControlRepository repository,
    [int frequencyIdSaveState = 10]
  ) => ErmesMessageControlService.createWithRepository(
    repository,
    ErmesMessageControlServiceOpts(frequencyIdSaveState: frequencyIdSaveState),
  );

  
  static ErmesMessageControlRepository createRepository() =>
      ErmesMessageControlRepository();

  
  static (ErmesMessageControlRepository, ErmesMessageControlService) createBoth(
    [int frequencyIdSaveState = 10]
  ) {
    final repo = createRepository();
    final service = createService(repo, frequencyIdSaveState);
    return (repo, service);
  }
}
