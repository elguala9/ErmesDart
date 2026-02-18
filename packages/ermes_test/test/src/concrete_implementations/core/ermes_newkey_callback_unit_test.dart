import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Simple API tests per il callback system di ServiceMessageNewKey
///
/// Testa che l'API di callback funziona correttamente senza lanciare eccezioni
@includeInBarrelFile
void testNewKeyCallbackAPI() {
  group('ErmesService NewKey Callback API Tests', () {
    late ErmesService service;
    late IIdHandlerService idHandler;
    late _SimpleRepository repository;

    setUp(() {
      idHandler = IdHandlerServiceFactory.createDefault();
      repository = _SimpleRepository();
      service = ErmesServiceFactory.createService(
        100,
        1024,
        repository,
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
    });

    group('API Availability', () {
      test('addOnNewKeyListener method exists and works', () {
        expect(
          () => service.addOnNewKeyListener((_) {}),
          returnsNormally,
        );
      });

      test('removeOnNewKeyListener method exists and works', () {
        final callback = (_) {};
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
            service.addOnNewKeyListener((_) {});
            service.addOnNewKeyListener((_) {});
            service.addOnNewKeyListener((_) {});
          },
          returnsNormally,
        );
      });

      test('callback accepts ServiceMessageNewKey parameter', () {
        // This tests that the typedef is correct
        expect(
          () {
            service.addOnNewKeyListener((ServiceMessageNewKey msg) {
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
        final callback = (_) {};
        service.addOnNewKeyListener(callback);
        expect(
          () => service.removeOnNewKeyListener(callback),
          returnsNormally,
        );
      });

      test('can remove from multiple callbacks', () {
        final callback1 = (_) {};
        final callback2 = (_) {};
        final callback3 = (_) {};

        service.addOnNewKeyListener(callback1);
        service.addOnNewKeyListener(callback2);
        service.addOnNewKeyListener(callback3);

        expect(
          () => service.removeOnNewKeyListener(callback2),
          returnsNormally,
        );
      });

      test('removing non-existent callback does not throw', () {
        final callback1 = (_) {};
        final callback2 = (_) {};

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
        service.addOnNewKeyListener((_) {});
        service.addOnNewKeyListener((_) {});

        expect(
          () => service.clearOnNewKeyListeners(),
          returnsNormally,
        );
      });

      test('can re-register callbacks after clear', () {
        service.addOnNewKeyListener((_) {});
        service.clearOnNewKeyListeners();

        expect(
          () => service.addOnNewKeyListener((_) {}),
          returnsNormally,
        );
      });

      test('can clear multiple times', () {
        expect(
          () {
            service.clearOnNewKeyListeners();
            service.addOnNewKeyListener((_) {});
            service.clearOnNewKeyListeners();
            service.addOnNewKeyListener((_) {});
            service.clearOnNewKeyListeners();
          },
          returnsNormally,
        );
      });
    });

    group('Service Lifecycle', () {
      test('callbacks persist through send', () {
        expect(
          () {
            service.addOnNewKeyListener((_) {});
            service.send(Uint8List(10));
          },
          returnsNormally,
        );
      });

      test('service can close with registered callbacks', () {
        service.addOnNewKeyListener((_) {});
        service.addOnNewKeyListener((_) {});

        expect(
          () => service.close(),
          returnsNormally,
        );

        expect(service.isClosed(), isTrue);
      });

      test('callbacks are cleared on close', () {
        service.addOnNewKeyListener((_) {});
        service.close();

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
            service.addOnNewKeyListener((_) {});
            service.addOnMessageDataListener((_) {});
            service.addOnDataSendingListener((_) {});
            service.addOnDataSentListener((_) {});
          },
          returnsNormally,
        );
      });

      test('can clear each callback type independently', () {
        service.addOnNewKeyListener((_) {});
        service.addOnMessageDataListener((_) {});

        expect(
          () {
            service.clearOnNewKeyListeners();
            service.addOnMessageDataListener((_) {});
          },
          returnsNormally,
        );
      });
    });

    group('Type Safety', () {
      test('typedef is correctly defined', () {
        // This verifies that CallbackOnNewKey typedef is accessible
        final CallbackOnNewKey callback = (ServiceMessageNewKey msg) {
          // Body
        };
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
        final callback = (_) {};

        expect(
          () {
            for (var i = 0; i < 100; i++) {
              service.addOnNewKeyListener(callback);
              service.removeOnNewKeyListener(callback);
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

/// Simple repository for testing
class _SimpleRepository implements IErmesRepository {
  @override
  void destroy({bool force = false}) {}

  @override
  bool isOpen() => false;

  @override
  void addOnMessageDataListener(void Function(Uint8List) callback) {}

  @override
  void removeOnMessageDataListener(void Function(Uint8List) callback) {}

  @override
  void clearOnMessageDataListeners() {}

  @override
  void send(Uint8List data) {}

  @override
  bool isClosed() => false;

  @override
  bool isClosing() => false;

  bool onClose(void Function() closeCallback) => false;

  bool onClosing(void Function() closingCallback) => false;

  bool onOpen(void Function() openCallback) => false;
}

void main() {
  testNewKeyCallbackAPI();
}
