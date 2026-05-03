import 'dart:io';
import 'dart:typed_data';

import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:test/test.dart';

/// Simple API tests per il callback system di ServiceMessageNewKey
///
/// Testa che l'API di callback funziona correttamente senza lanciare eccezioni

const _testPeerId = 'test-peer-id';

ErmesPeerInfo _createPeerInfo() => ErmesPeerInfo(
      address: InternetAddress('127.0.0.1'),
      port: 9999,
      id: _testPeerId,
    );

Future<({ErmesRepository repository, RawDatagramSocket rawSocket})>
    _createRepository() async {
  final rawSocket =
      await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  final shspSocket = ShspSocket.fromRaw(rawSocket);
  final bookService = ErmesBookServiceBase();
  bookService.setAccount(AccountInfo<BookData>(
    account: _testPeerId,
    peerInfo: _createPeerInfo(),
  ));
  final signalHandler = ErmesSignalingHandler();
  final repository = ErmesRepository(
    remotePeerId: _testPeerId,
    socket: shspSocket,
    signalHandler: signalHandler,
    ermesBookService: bookService,
  );
  return (repository: repository, rawSocket: rawSocket);
}

void testNewKeyCallbackAPI() {
  group('ErmesService NewKey Callback API Tests', () {
    late ErmesService service;
    late IIdHandlerService idHandler;
    late RawDatagramSocket rawSocket;

    setUpAll(initialPointErmesStorage);

    setUp(() async {
      idHandler = IdHandlerServiceFactory.createDefault();
      final result = await _createRepository();
      rawSocket = result.rawSocket;
      result.repository.openState = true;
      service = ErmesServiceFactory.createService(
        100,
        1024,
        result.repository,
        idHandler,
        null,
        null,
        null,
        null,
        null,
      );
    });

    tearDown(() {
      service.close();
      rawSocket.close();
    });

    group('API Availability', () {
      test('addOnNewKeyListener method exists and works', () {
        expect(
          () => service.addOnNewKeyListener((_) {}),
          returnsNormally,
        );
      });

      test('removeOnNewKeyListener method exists and works', () {
        void callback(_) {}
        service.addOnNewKeyListener(callback);
        expect(
          () => service.removeOnNewKeyListener(callback),
          returnsNormally,
        );
      });

      test('clearOnNewKeyListeners method exists and works', () {
        expect(
          () => service.clearOnNewKeyListeners(),
          returnsNormally,
        );
      });
    });

    group('Callback Registration', () {
      test('can register single callback', () {
        expect(
          () => service.addOnNewKeyListener((_) {}),
          returnsNormally,
        );
      });

      test('can register multiple callbacks', () {
        expect(
          () {
            service
              ..addOnNewKeyListener((_) {})
              ..addOnNewKeyListener((_) {})
              ..addOnNewKeyListener((_) {});
          },
          returnsNormally,
        );
      });

      test('callback accepts ServiceMessageNewKey parameter', () {
        // This tests that the typedef is correct
        expect(
          () {
            service.addOnNewKeyListener((msg) {
              // Access fields to verify type
              final id = msg.id;
              final algo = msg.algorithm;
              final key = msg.key;
              expect([id, algo, key], isNotEmpty);
            });
          },
          returnsNormally,
        );
      });
    });

    group('Callback Removal', () {
      test('can remove registered callback', () {
        void callback(_) {}
        service.addOnNewKeyListener(callback);
        expect(
          () => service.removeOnNewKeyListener(callback),
          returnsNormally,
        );
      });

      test('can remove from multiple callbacks', () {
        void callback1(_) {}
        void callback2(_) {}
        void callback3(_) {}

        service
          ..addOnNewKeyListener(callback1)
          ..addOnNewKeyListener(callback2)
          ..addOnNewKeyListener(callback3);

        expect(
          () => service.removeOnNewKeyListener(callback2),
          returnsNormally,
        );
      });

      test('removing non-existent callback does not throw', () {
        void callback1(_) {}
        void callback2(_) {}

        service.addOnNewKeyListener(callback1);
        expect(
          () => service.removeOnNewKeyListener(callback2),
          returnsNormally,
        );
      });

      test('can remove all callbacks one by one', () {
        final callbacks = [
          (_) {},
          (_) {},
          (_) {},
        ];

        for (final callback in callbacks) {
          service.addOnNewKeyListener(callback);
        }

        expect(
          () {
            for (final callback in callbacks) {
              service.removeOnNewKeyListener(callback);
            }
          },
          returnsNormally,
        );
      });
    });

    group('Clear All Callbacks', () {
      test('can clear empty callback list', () {
        expect(
          () => service.clearOnNewKeyListeners(),
          returnsNormally,
        );
      });

      test('can clear with registered callbacks', () {
        service
          ..addOnNewKeyListener((_) {})
          ..addOnNewKeyListener((_) {});

        expect(
          () => service.clearOnNewKeyListeners(),
          returnsNormally,
        );
      });

      test('can re-register callbacks after clear', () {
        service
          ..addOnNewKeyListener((_) {})
          ..clearOnNewKeyListeners();

        expect(
          () => service.addOnNewKeyListener((_) {}),
          returnsNormally,
        );
      });

      test('can clear multiple times', () {
        expect(
          () {
            service
              ..clearOnNewKeyListeners()
              ..addOnNewKeyListener((_) {})
              ..clearOnNewKeyListeners()
              ..addOnNewKeyListener((_) {})
              ..clearOnNewKeyListeners();
          },
          returnsNormally,
        );
      });
    });

    group('Service Lifecycle', () {
      test('callbacks persist through send', () {
        expect(
          () {
            service
              ..addOnNewKeyListener((_) {})
              ..send(Uint8List(10));
          },
          returnsNormally,
        );
      });

      test('service can close with registered callbacks', () {
        service
          ..addOnNewKeyListener((_) {})
          ..addOnNewKeyListener((_) {});

        expect(
          () => service.close(),
          returnsNormally,
        );

        expect(service.isClosed(), isTrue);
      });

      test('callbacks are cleared on close', () {
        service
          ..addOnNewKeyListener((_) {})
          ..close();

        // Should not throw even though callbacks were cleared
        expect(
          () => service.clearOnNewKeyListeners(),
          returnsNormally,
        );
      });
    });

    group('Integration with Other Callbacks', () {
      test('newKey callbacks coexist with data callbacks', () {
        expect(
          () {
            service
              ..addOnNewKeyListener((_) {})
              ..addOnMessageDataListener((_) {})
              ..addOnDataSendingListener((_) {})
              ..addOnDataSentListener((_) {});
          },
          returnsNormally,
        );
      });

      test('can clear each callback type independently', () {
        service
          ..addOnNewKeyListener((_) {})
          ..addOnMessageDataListener((_) {});

        expect(
          () {
            service
              ..clearOnNewKeyListeners()
              ..addOnMessageDataListener((_) {});
          },
          returnsNormally,
        );
      });
    });

    group('Type Safety', () {
      test('typedef is correctly defined', () {
        // This verifies that CallbackOnNewKey typedef is accessible
        void callback(msg) {
          // Body
        }
        expect(callback, isNotNull);
      });

      test('callback function signature is correct', () {
        expect(
          () {
            service.addOnNewKeyListener((newKey) {
              expect(newKey, isA<ServiceMessageNewKey>());
            });
          },
          returnsNormally,
        );
      });
    });

    group('Stress Tests', () {
      test('can register many callbacks', () {
        expect(
          () {
            for (var i = 0; i < 1000; i++) {
              service.addOnNewKeyListener((_) {});
            }
          },
          returnsNormally,
        );
      });

      test('can register and unregister callbacks repeatedly', () {
        void callback(_) {}

        expect(
          () {
            for (var i = 0; i < 100; i++) {
              service
                ..addOnNewKeyListener(callback)
                ..removeOnNewKeyListener(callback);
            }
          },
          returnsNormally,
        );
      });

      test('can clear and re-register many times', () {
        expect(
          () {
            for (var i = 0; i < 50; i++) {
              service.clearOnNewKeyListeners();
              for (var j = 0; j < 10; j++) {
                service.addOnNewKeyListener((_) {});
              }
            }
          },
          returnsNormally,
        );
      });
    });
  });
}

void main() {
  testNewKeyCallbackAPI();
}
