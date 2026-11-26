import 'package:ermes_core/ermes_core.dart';
import 'package:singleton_manager/singleton_manager.dart';

/// Registers the orchestrator's NAT settings under [key]: the signal
/// republisher configuration and the symmetric-NAT detector, both resolved by
/// `OrcErmes.dependencyInjectionFactory`.
void registerOrchestratorSettings({
  required String key,
  required OrcSignalRepublishSettings signalRepublish,
  required int symmetricNatMaxFailedAttempts,
}) {
  if (symmetricNatMaxFailedAttempts < 0) {
    throw ArgumentError.value(
      symmetricNatMaxFailedAttempts,
      'symmetricNatMaxFailedAttempts',
      'must be >= 0 (0 disables detection)',
    );
  }
  RegistryManager.instance
    ..setInstance<OrcSignalRepublishSettings>(signalRepublish, key: key)
    ..setInstance<OrcSymmetricNatDetector>(
      OrcSymmetricNatDetector(
        maxFailedAttempts: symmetricNatMaxFailedAttempts,
      ),
      key: key,
    );
}
