import 'package:iermes/iermes.dart';

import '../ermes_signaling_repository.dart';
import '../ermes_signaling_service.dart';

/// 🔟 Factory per Signaling
/// Tradotto da: ErmesSignalingFactory.ts
class ErmesSignalingFactory {
  static ErmesSignalingService createService(
    IErmesSignalingRepository<dynamic> repository,
  ) =>
      ErmesSignalingService(repository);

  static ErmesSignalingRepository createRepository(
    IErmesSignalingServer signalingServer,
    IErmesSignalingHandler<dynamic> signalHandler,
  ) =>
      ErmesSignalingRepository(signalingServer, signalHandler);

  static (ErmesSignalingRepository, ErmesSignalingService) createBoth(
    IErmesSignalingServer signalingServer,
    IErmesSignalingHandler<dynamic> signalHandler,
  ) {
    final repo = createRepository(signalingServer, signalHandler);
    final service = createService(repo);
    return (repo, service);
  }
}
