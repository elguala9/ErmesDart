import 'dart:typed_data';

import 'package:cryptdart/cryptdart.dart';
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_core_init/ermes_core_init.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:test/test.dart';

import '../../../helpers/test_helpers.dart';

/// Asserts every datagram ErmesSendRepo emits stays under the MTU-safe cap,
/// for plaintext and encrypted links and for small, medium and large payloads.
void testDatagramSize() {
  group('ErmesSendRepo datagram size cap', () {
    late TestErmesRepository repository;

    setUpAll(registerErmesStorageHandlers);

    setUp(() async {
      repository = await TestErmesRepository.create(open: true);
    });

    tearDown(() {
      ErmesPeerCipherHandler().remove(repository.remotePeerId);
      repository.cleanUp();
    });

    void registerCipher() {
      final cipher = generateSymmetric('A' * 64, SymmetricAlgorithm.aes);
      final peerCipher = ErmesPeerCipher()
        ..addEncryptCipher(cipher)
        ..addDecryptCipher(cipher);
      ErmesPeerCipherHandler().set(repository.remotePeerId, peerCipher);
    }

    Future<void> sendAndCheck(int size) async {
      final sendRepo =
          ErmesSendRepo(repository, IdHandlerServiceFactory.createDefault());
      final data = Uint8List.fromList(List<int>.generate(size, (i) => i));
      await sendRepo.send(data);
      expect(repository.sentData, isNotEmpty);
      final total = repository.sentData.fold<int>(
        0,
        (sum, d) => sum + d.length,
      );
      expect(total, greaterThan(size));
      for (final datagram in repository.sentData) {
        expect(datagram.length, lessThanOrEqualTo(ermesMaxDatagramBytes));
      }
    }

    for (final size in [1024, 64 * 1024, 2 * 1024 * 1024]) {
      test('plaintext $size B payload stays under cap', () async {
        await sendAndCheck(size);
      }, timeout: const Timeout(Duration(minutes: 3)));

      test('encrypted $size B payload stays under cap', () async {
        registerCipher();
        await sendAndCheck(size);
      }, timeout: const Timeout(Duration(minutes: 3)));
    }

    test('ensureDatagramFits rejects an oversized datagram', () {
      expect(
        () => ensureDatagramFits(Uint8List(ermesMaxDatagramBytes + 1)),
        throwsA(isA<CoreException>()),
      );
      expect(() => ensureDatagramFits(Uint8List(10)), returnsNormally);
    });

    test('sizer shrinks chunk size when encryption is active', () {
      const sizer = ErmesDatagramSizer(ermesMaxDatagramBytes);
      final plain = sizer.chunkSizeFor(repository.remotePeerId, 1 << 21);
      registerCipher();
      final encrypted = sizer.chunkSizeFor(repository.remotePeerId, 1 << 21);
      expect(encrypted, lessThan(plain));
      expect(encrypted, greaterThan(0));
    });
  });
}

/// Standalone entry point.
void main() => testDatagramSize();
