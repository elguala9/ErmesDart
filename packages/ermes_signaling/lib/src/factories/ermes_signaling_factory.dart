import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';

import '../ermes_signaling_repository.dart';
import '../ermes_signaling_service.dart';

// ignore: avoid_classes_with_only_static_members
/// Factory per Signaling
/// Tradotto da: ErmesSignalingFactory.ts

class ErmesSignalingFactory {
  
  static ErmesSignalingService createService(
    IErmesSignalingRepository<ISignalErmes> repository,
  ) => ErmesSignalingService(repository);

  
  static ErmesSignalingRepository createRepository(
    IErmesSignalingServer signalingServer,
    IErmesSignalingHandler<IShspPeer> signalHandler,
  ) => ErmesSignalingRepository(signalingServer, signalHandler);

  static (ErmesSignalingRepository, ErmesSignalingService) createBoth(
    IErmesSignalingServer signalingServer,
    IErmesSignalingHandler<IShspPeer> signalHandler,
  ) {
    final repo = createRepository(signalingServer, signalHandler);
    final service = createService(repo);
    return (repo, service);
  }
}
