
import 'package:iermes/iermes.dart';

import 'ermes_message_control_repository.dart';
import 'ermes_message_control_service.dart';

/// 8️⃣ Factory per Message Control
/// Tradotto da: ErmesMessageControlFactory.ts

class ErmesMessageControlFactory {
  /// Private constructor to prevent instantiation of this static factory.
  ErmesMessageControlFactory._();

  /// Creates a message control service wired to the given [repository],
  /// with an optional save-state frequency.
  static ErmesMessageControlService createService(
    IErmesMessageControlRepository repository,
    [int frequencyIdSaveState = 10]
  ) => ErmesMessageControlService.createWithRepository(
    repository,
    ErmesMessageControlServiceOpts(frequencyIdSaveState: frequencyIdSaveState),
  );

  /// Creates a standalone message control repository.
  static ErmesMessageControlRepository createRepository() =>
      ErmesMessageControlRepository();

  /// Creates and wires together a repository and its service, returning both.
  static (ErmesMessageControlRepository, ErmesMessageControlService) createBoth(
    [int frequencyIdSaveState = 10]
  ) {
    final repo = createRepository();
    final service = createService(repo, frequencyIdSaveState);
    return (repo, service);
  }
}
