import 'package:ermes_implementation/ermes_implementation.dart';
import 'package:ermes_test/ermes_test.dart';
import 'package:iermes/iermes.dart';
import 'package:shsp_implementations/shsp_implementations.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:shsp_types/shsp_types.dart';
import 'package:test/test.dart';

void testErmesRepository(
  String name,
  PeerInfo peerInfo,
  IShspSocket socket,
  IErmesSignalingHandler<IShspSocket> signalHandler,
) {
  group('ErmesRepository Implementation Tests - $name', () {
    // Test the interface contract
    testIErmesRepository(
      'ErmesRepository',
      () => ErmesRepository(
        remotePeer: peerInfo,
        socket: socket,
        remotePeerId: 'test-peer-id',
        signalHandler: signalHandler,
      ),
    );

    // Additional specific tests for ErmesRepository
    group('ErmesRepository Specific Tests', () {
      test('should inherit from ShspPeer', () {
        final repo = ErmesRepository(
          remotePeer: peerInfo,
          socket: socket,
          remotePeerId: 'test-peer-id',
          signalHandler: signalHandler,
        );
        expect(repo, isA<ShspPeer>());
        repo.destroy();
      });

      test('should implement IErmesRepository', () {
        final repo = ErmesRepository(
          remotePeer: peerInfo,
          socket: socket,
          remotePeerId: 'test-peer-id',
          signalHandler: signalHandler,
        );
        expect(repo, isA<IErmesRepository>());
        repo.destroy();
      });
    });
  });
}

void main() {
  // To use this test, provide the factory functions:
  // testErmesRepository(
  //   'Implementation Name',
  //   () => PeerInfo(...),
  //   () => MockSocket(...),
  //   () => MockSignalHandler(...),
  // );
}
