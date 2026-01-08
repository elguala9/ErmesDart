import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import '../ermes_signaling_repository.dart';
import '../ermes_signaling_service.dart';

/// 🔟 Factory per Signaling
/// Tradotto da: ErmesSignalingFactory.ts
@includeInBarrelFile
class ErmesSignalingFactory {
  @includeInBarrelFile
  static ErmesSignalingService createService(
    IErmesSignalingRepository<dynamic> repository,
  ) => ErmesSignalingService(repository);

  @includeInBarrelFile
  static ErmesSignalingRepository createRepository(
    IErmesSignalingServer signalingServer,
    IErmesSignalingHandler<dynamic> signalHandler,
  ) => ErmesSignalingRepository(signalingServer, signalHandler);

  static (ErmesSignalingRepository, ErmesSignalingService) createBoth(
    IErmesSignalingServer signalingServer,
    IErmesSignalingHandler<dynamic> signalHandler,
  ) {
    final repo = createRepository(signalingServer, signalHandler);
    final service = createService(repo);
    return (repo, service);
  }
}
