import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ermes_core/ermes_core.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

void testObservableQueue() {
  group('ObservableQueue', () {
    group('push() and shift()', () {
      test('push adds item and shift removes it', () {
        final queue = ObservableQueue<int>();
        queue.push(42);
        expect(queue.shift(), equals(42));
      });

      test('push respects FIFO order', () {
        final queue = ObservableQueue<int>();
        queue.push(1);
        queue.push(2);
        queue.push(3);
        expect(queue.shift(), equals(1));
        expect(queue.shift(), equals(2));
        expect(queue.shift(), equals(3));
      });

      test('push with maxSize throws StateError when full', () {
        final queue = ObservableQueue<int>(2);
        queue.push(1);
        queue.push(2);
        expect(
          () => queue.push(3),
          throwsA(isA<StateError>()),
        );
      });

      test('push without maxSize never throws', () {
        final queue = ObservableQueue<int>();
        for (var i = 0; i < 1000; i++) {
          queue.push(i);
        }
        expect(queue.length, equals(1000));
      });
    });

    group('shift()', () {
      test('throws StateError when empty', () {
        final queue = ObservableQueue<int>();
        expect(
          () => queue.shift(),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('isEmpty()', () {
      test('returns true for new queue', () {
        final queue = ObservableQueue<int>();
        expect(queue.isEmpty(), isTrue);
      });

      test('returns false after push', () {
        final queue = ObservableQueue<int>();
        queue.push(1);
        expect(queue.isEmpty(), isFalse);
      });

      test('returns true after shift all', () {
        final queue = ObservableQueue<int>();
        queue.push(1);
        queue.push(2);
        queue.shift();
        queue.shift();
        expect(queue.isEmpty(), isTrue);
      });
    });

    group('length', () {
      test('starts at 0', () {
        final queue = ObservableQueue<int>();
        expect(queue.length, equals(0));
      });

      test('increases with push', () {
        final queue = ObservableQueue<int>();
        queue.push(1);
        queue.push(2);
        expect(queue.length, equals(2));
      });

      test('decreases with shift', () {
        final queue = ObservableQueue<int>();
        queue.push(1);
        queue.push(2);
        queue.shift();
        expect(queue.length, equals(1));
      });
    });

    group('clear()', () {
      test('removes all items', () {
        final queue = ObservableQueue<int>();
        queue.push(1);
        queue.push(2);
        queue.push(3);
        queue.clear();
        expect(queue.isEmpty(), isTrue);
        expect(queue.length, equals(0));
      });

      test('is idempotent', () {
        final queue = ObservableQueue<int>();
        queue.clear();
        queue.clear();
        expect(queue.isEmpty(), isTrue);
      });
    });

    group('onAddCallback', () {
      test('is called when item is pushed', () {
        final queue = ObservableQueue<int>();
        var callbackCalled = false;
        queue.onAddCallback = () {
          callbackCalled = true;
        };
        queue.push(42);
        expect(callbackCalled, isTrue);
      });

      test('is not called when queue is empty', () {
        final queue = ObservableQueue<int>();
        var callbackCalled = false;
        queue.onAddCallback = () {
          callbackCalled = true;
        };
        expect(callbackCalled, isFalse);
      });

      test('can be cleared', () {
        final queue = ObservableQueue<int>();
        var callbackCalled = false;
        queue.onAddCallback = () {
          callbackCalled = true;
        };
        queue.onAddCallback = null;
        queue.push(42);
        expect(callbackCalled, isFalse);
      });
    });

    group('edge cases', () {
      test('push and shift single item repeatedly', () {
        final queue = ObservableQueue<int>();
        for (var i = 0; i < 10; i++) {
          queue.push(i);
          expect(queue.shift(), equals(i));
          expect(queue.isEmpty(), isTrue);
        }
      });

      test('maxSize 0 throws on push', () {
        final queue = ObservableQueue<int>(0);
        expect(
          () => queue.push(1),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}

void testChunkHandler() {
  group('ChunkHandler', () {
    group('addChunk()', () {
      test('returns null for first chunk when roof > 1', () {
        final handler = ChunkHandler('msg-1', 2);
        final result = handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([1, 2, 3]),
          index: 0,
          roof: 2,
          id: 1,
          refId: 'msg-1',
        ));
        expect(result, isNull);
      });

      test('returns complete data on last chunk', () {
        final handler = ChunkHandler('msg-1', 2);
        handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([1, 2]),
          index: 0,
          roof: 2,
          id: 1,
          refId: 'msg-1',
        ));
        final result = handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([3, 4]),
          index: 1,
          roof: 2,
          id: 2,
          refId: 'msg-1',
        ));
        expect(result, isNotNull);
        expect(result as Uint8List, equals([1, 2, 3, 4]));
      });

      test('handles single chunk message', () {
        final handler = ChunkHandler('msg-1', 1);
        final result = handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([42]),
          index: 0,
          roof: 1,
          id: 1,
          refId: 'msg-1',
        ));
        expect(result, isNotNull);
        expect(result as Uint8List, equals([42]));
      });
    });

    group('duplicate detection', () {
      test('ignores duplicate chunk index', () {
        final handler = ChunkHandler('msg-1', 2);
        handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([1]),
          index: 0,
          roof: 2,
          id: 1,
          refId: 'msg-1',
        ));
        // Duplicate of index 0 should be ignored
        final dupResult = handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([99]),
          index: 0,
          roof: 2,
          id: 2,
          refId: 'msg-1',
        ));
        expect(dupResult, isNull);
      });

      test('final result uses original chunk data, not duplicate', () {
        final handler = ChunkHandler('msg-1', 2);
        handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([1]),
          index: 0,
          roof: 2,
          id: 1,
          refId: 'msg-1',
        ));
        // Duplicate index 0
        handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([99]),
          index: 0,
          roof: 2,
          id: 2,
          refId: 'msg-1',
        ));
        final result = handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([2]),
          index: 1,
          roof: 2,
          id: 3,
          refId: 'msg-1',
        ));
        expect(result, isNotNull);
        expect((result as Uint8List), equals([1, 2]));
      });
    });

    group('createData()', () {
      test('returns null when not complete', () {
        final handler = ChunkHandler('msg-1', 3);
        handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([1]),
          index: 0,
          roof: 3,
          id: 1,
          refId: 'msg-1',
        ));
        expect(handler.createData(), isNull);
      });

      test('returns data when complete', () {
        final handler = ChunkHandler('msg-1', 2);
        handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([1]),
          index: 0,
          roof: 2,
          id: 1,
          refId: 'msg-1',
        ));
        handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([2]),
          index: 1,
          roof: 2,
          id: 2,
          refId: 'msg-1',
        ));
        final result = handler.createData();
        expect(result, isNotNull);
        expect(result as Uint8List, equals([1, 2]));
      });
    });

    group('getMissingChunkIndices()', () {
      test('returns all indices when no chunks added', () {
        final handler = ChunkHandler('msg-1', 3);
        expect(handler.getMissingChunkIndices(), equals([0, 1, 2]));
      });

      test('returns only missing indices', () {
        final handler = ChunkHandler('msg-1', 5);
        handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([1]),
          index: 0,
          roof: 5,
          id: 1,
          refId: 'msg-1',
        ));
        handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([3]),
          index: 2,
          roof: 5,
          id: 2,
          refId: 'msg-1',
        ));
        expect(handler.getMissingChunkIndices(), equals([1, 3, 4]));
      });

      test('returns empty list when complete', () {
        final handler = ChunkHandler('msg-1', 2);
        handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([1]),
          index: 0,
          roof: 2,
          id: 1,
          refId: 'msg-1',
        ));
        handler.addChunk(ChunkMessage(
          data: Uint8List.fromList([2]),
          index: 1,
          roof: 2,
          id: 2,
          refId: 'msg-1',
        ));
        expect(handler.getMissingChunkIndices(), isEmpty);
      });
    });

    group('getId()', () {
      test('returns the chunk id', () {
        final handler = ChunkHandler('test-id', 3);
        expect(handler.getId(), equals('test-id'));
      });
    });
  });
}

void testComposeUint8Array() {
  group('composeUint8Array()', () {
    test('concatenates multiple arrays', () {
      final result = composeUint8Array([
        Uint8List.fromList([1, 2]),
        Uint8List.fromList([3, 4]),
        Uint8List.fromList([5, 6]),
      ]);
      expect(result, equals([1, 2, 3, 4, 5, 6]));
    });

    test('returns empty array for empty input', () {
      final result = composeUint8Array([]);
      expect(result, isEmpty);
    });

    test('handles single array', () {
      final result = composeUint8Array([
        Uint8List.fromList([42]),
      ]);
      expect(result, equals([42]));
    });

    test('preserves order', () {
      final result = composeUint8Array([
        Uint8List.fromList([1]),
        Uint8List.fromList([2, 3]),
        Uint8List.fromList([4]),
      ]);
      expect(result, equals([1, 2, 3, 4]));
    });
  });
}

void testGetMissingIndices() {
  group('getMissingIndices()', () {
    test('returns all indices when no numbers provided', () {
      expect(getMissingIndices([], 5), equals([0, 1, 2, 3, 4]));
    });

    test('returns only missing numbers', () {
      expect(getMissingIndices([0, 2, 4], 5), equals([1, 3]));
    });

    test('returns empty when all indices present', () {
      expect(getMissingIndices([0, 1, 2], 3), isEmpty);
    });

    test('handles unsorted input', () {
      expect(getMissingIndices([3, 1, 0], 4), equals([2]));
    });

    test('handles duplicates', () {
      expect(getMissingIndices([0, 0, 1, 1, 2], 4), equals([3]));
    });

    test('handles max 0', () {
      expect(getMissingIndices([], 0), isEmpty);
    });
  });
}

void testHashUtils() {
  group('Hash Utils', () {
    group('calculateHashSync()', () {
      test('returns a non-empty string', () {
        final data = Uint8List.fromList([1, 2, 3]);
        final hash = calculateHashSync(data);
        expect(hash, isNotEmpty);
      });

      test('returns consistent results for same input', () {
        final data = Uint8List.fromList([1, 2, 3]);
        final hash1 = calculateHashSync(data);
        final hash2 = calculateHashSync(data);
        expect(hash1, equals(hash2));
      });

      test('returns different results for different input', () {
        final hash1 = calculateHashSync(Uint8List.fromList([1, 2, 3]));
        final hash2 = calculateHashSync(Uint8List.fromList([4, 5, 6]));
        expect(hash1, isNot(equals(hash2)));
      });

      test('returns SHA-256 hash (64 hex chars)', () {
        final data = Uint8List.fromList([1, 2, 3]);
        final hash = calculateHashSync(data);
        expect(hash.length, equals(64));
        expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
      });

      test('handles empty data', () {
        final hash = calculateHashSync(Uint8List(0));
        expect(hash, isNotEmpty);
        expect(hash.length, equals(64));
      });
    });

    group('verifyHash()', () {
      test('returns true for matching data and hash', () {
        final data = Uint8List.fromList([1, 2, 3]);
        final hash = calculateHashSync(data);
        expect(verifyHash(data, hash), isTrue);
      });

      test('returns false for different data', () {
        final data = Uint8List.fromList([1, 2, 3]);
        final hash = calculateHashSync(Uint8List.fromList([4, 5, 6]));
        expect(verifyHash(data, hash), isFalse);
      });

      test('returns false for tampered data', () {
        final original = Uint8List.fromList([1, 2, 3]);
        final hash = calculateHashSync(original);
        final tampered = Uint8List.fromList([1, 2, 4]);
        expect(verifyHash(tampered, hash), isFalse);
      });
    });
  });
}

void testUtilityFunctions() {
  group('Utility Functions', () {
    group('chunkArrayBuffer()', () {
      test('splits data into correct number of chunks', () {
        final idHandler = IdHandlerServiceFactory.createDefault();
        final data = Uint8List.fromList(List.generate(1000, (i) => i % 256));
        final chunks = chunkArrayBuffer(idHandler, data, 'ref-1', 300);
        expect(chunks.length, equals(4));
      });

      test('chunks have correct metadata', () {
        final idHandler = IdHandlerServiceFactory.createDefault();
        final data = Uint8List.fromList(List.generate(500, (i) => i % 256));
        final chunks = chunkArrayBuffer(idHandler, data, 'ref-1', 200);
        expect(chunks.length, equals(3));
        for (var i = 0; i < chunks.length; i++) {
          expect(chunks[i].index, equals(i));
          expect(chunks[i].refId, equals('ref-1'));
          expect(chunks[i].roof, equals(3));
        }
      });

      test('last chunk may be smaller than maxByte', () {
        final idHandler = IdHandlerServiceFactory.createDefault();
        final data = Uint8List.fromList(List.generate(250, (i) => i % 256));
        final chunks = chunkArrayBuffer(idHandler, data, 'ref-1', 100);
        expect(chunks.length, equals(3));
        expect(chunks[0].data.length, equals(100));
        expect(chunks[1].data.length, equals(100));
        expect(chunks[2].data.length, equals(50));
      });

      test('handles data smaller than maxByte', () {
        final idHandler = IdHandlerServiceFactory.createDefault();
        final data = Uint8List.fromList([1, 2, 3]);
        final chunks = chunkArrayBuffer(idHandler, data, 'ref-1', 100);
        expect(chunks.length, equals(1));
        expect(chunks[0].data, equals([1, 2, 3]));
      });

      test('data length equal to maxByte produces one chunk', () {
        final idHandler = IdHandlerServiceFactory.createDefault();
        final data = Uint8List.fromList(List.generate(100, (i) => i % 256));
        final chunks = chunkArrayBuffer(idHandler, data, 'ref-1', 100);
        expect(chunks.length, equals(1));
      });

      test('chunk data reassembles to original', () {
        final idHandler = IdHandlerServiceFactory.createDefault();
        final original = Uint8List.fromList(List.generate(1000, (i) => i % 256));
        final chunks = chunkArrayBuffer(idHandler, original, 'ref-1', 300);
        final reassembled = composeUint8Array(
          chunks.map((c) => c.data).toList(),
        );
        expect(reassembled, equals(original));
      });
    });

    group('getMessageType()', () {
      test('returns base for MessageData', () {
        final msg = MessageType.data(MessageData(id: 1, data: Uint8List(0)));
        expect(getMessageType(msg), equals(MessageValue.base));
      });

      test('returns chunk for ChunkMessage', () {
        final msg = MessageType.chunk(ChunkMessage(
          data: Uint8List(0),
          index: 0,
          roof: 1,
          id: 1,
          refId: 'ref',
        ));
        expect(getMessageType(msg), equals(MessageValue.chunk));
      });

      test('returns service for ServiceMessage', () {
        const msg = MessageType.service(ServiceMessageAcknowledge(id: 1));
        expect(getMessageType(msg), equals(MessageValue.service));
      });
    });

    group('createMessageDataErmes()', () {
      test('creates MessageData with correct id and data', () {
        final data = Uint8List.fromList([1, 2, 3]);
        final msg = createMessageDataErmes(data, 42);
        expect(msg.id, equals(42));
        expect(msg.data, equals([1, 2, 3]));
      });
    });

    group('createMessageDataErmesWithNewId()', () {
      test('creates MessageData with new id from handler', () {
        final idHandler = IdHandlerServiceFactory.createDefault();
        final data = Uint8List.fromList([10, 20, 30]);
        final msg = createMessageDataErmesWithNewId(idHandler, data);
        expect(msg.data, equals([10, 20, 30]));
        expect(msg.id, greaterThanOrEqualTo(0));
      });
    });

    group('objectToUint8Array()', () {
      test('serializes IErmesSerializable to bytes', () {
        final data = Uint8List.fromList([1, 2, 3]);
        final msg = MessageData(id: 1, data: data);
        final result = objectToUint8Array(msg);
        expect(result, isA<Uint8List>());
        expect(result.length, greaterThan(0));
      });
    });

    group('uint8ArrayToObject()', () {
      test('deserializes valid JSON data', () {
        final msg = MessageData(id: 1, data: Uint8List.fromList([1, 2, 3]));
        SerializationRegistry.register<MessageData>(MessageData.fromJson);
        final serialized = objectToUint8Array(msg);
        final deserialized = uint8ArrayToObject<MessageData>(serialized);
        expect(deserialized.id, equals(1));
        expect(deserialized.data, equals([1, 2, 3]));
      });
    });
  });
}

void main() {
  testObservableQueue();
  testChunkHandler();
  testComposeUint8Array();
  testGetMissingIndices();
  testHashUtils();
  testUtilityFunctions();
}
