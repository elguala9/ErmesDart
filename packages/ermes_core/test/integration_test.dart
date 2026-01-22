import 'dart:async';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_test/ermes_test.dart';

// Simple global in-memory message bus used by test doubles
final _messageBus = StreamController<Uint8List>.broadcast();

void main() {
  // Pass factory lambdas so the test-suite can create fresh instances per test
  // and avoid shared-state between tests.
  final factory = ErmesFactory(); // IA: usa la factory dedicata
  testIErmesRepository(
    'ermes_core (factory)',
    () => ErmesRepositoryFactory.create(
      remotePeer: PeerInfo(),
      socket: TestShspSocket(),
      remotePeerId: 'test-peer',
      signalHandler: TestSignalingHandler(),
    ),
    () => ErmesRepositoryFactory.create(
      remotePeer: PeerInfo(),
      socket: TestShspSocket(),
      remotePeerId: 'test-peer',
      signalHandler: TestSignalingHandler(),
    ),
  );
}
