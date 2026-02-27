import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import 'ermes_message_control_repository.dart';
import 'ermes_message_control_service.dart';

/// 8️⃣ Factory per Message Control
/// Tradotto da: ErmesMessageControlFactory.ts
@includeInBarrelFile
class ErmesMessageControlFactory {
  ErmesMessageControlFactory._();

  @includeInBarrelFile
  static ErmesMessageControlService createService(
    IErmesMessageControlRepository repository,
    int frequencyIdSaveState,
  ) => ErmesMessageControlService(
    repository,
    ErmesMessageControlServiceOpts(frequencyIdSaveState: frequencyIdSaveState),
  );

  @includeInBarrelFile
  static ErmesMessageControlRepository createRepository() =>
      ErmesMessageControlRepository();

  @includeInBarrelFile
  static (ErmesMessageControlRepository, ErmesMessageControlService) createBoth(
    int frequencyIdSaveState,
  ) {
    final repo = createRepository();
    final service = createService(repo, frequencyIdSaveState);
    return (repo, service);
  }
}
