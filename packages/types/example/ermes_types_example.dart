// ignore_for_file: avoid_print, cascade_invocations, avoid_dynamic_calls

import 'dart:typed_data';

import 'package:ermes_types/ermes_types.dart';

void main() {
  print('=== Ermes Types Examples ===\n');

  demonstrateMessageTypes();
  demonstrateChunking();
  demonstrateServiceMessages();
  demonstratePagination();
  demonstrateSignaling();
  demonstrateCallbacks();
}

void demonstrateMessageTypes() {
  print('--- Message Types ---');

  // Create a simple data message
  final dataMessage = MessageData(
    id: 1,
    data: Uint8List.fromList([72, 101, 108, 108, 111]), // "Hello"
  );
  print('Data Message ID: ${dataMessage.id}');
  print('Data Length: ${dataMessage.data.length} bytes\n');

  // Use MessageType union
  final messageType = MessageType.data(
    MessageData(id: 2, data: Uint8List.fromList([])),
  );

  messageType.when(
    data: (msg) => print('Handling data message: ${msg.id}'),
    chunk: (msg) => print('Handling chunk message: ${msg.index}/${msg.roof}'),
    service: (msg) => print('Handling service message: ${msg.reason}'),
  );
  print('');
}

void demonstrateChunking() {
  print('--- Chunking Large Data ---');

  // Simulate sending a large file in chunks
  const totalChunks = 5;
  const refId = 'file-abc-123';

  for (var i = 0; i < totalChunks; i++) {
    final chunk = ChunkMessage(
      id: i + 1,
      data: Uint8List.fromList(List.generate(100, (index) => i * 10 + index)),
      refId: refId,
      index: i,
      roof: totalChunks,
    );

    print('Chunk ${chunk.index + 1}/$totalChunks (ID: ${chunk.id}, '
        'RefID: ${chunk.refId})');
  }
  print('');
}

void demonstrateServiceMessages() {
  print('--- Service Messages ---');

  // Completed message
  const completed = ServiceMessage(
    id: 100,
    reason: ServiceReasons.completed,
  );
  print('Service: ${completed.reason} (completed)');

  // Request retransmission
  const retry = ServiceMessage(
    id: 101,
    reason: ServiceReasons.sendAgain,
    arrayChunkInfo: [
      ChunkInfo(chunkId: 3, index: [0, 1, 2]),
      ChunkInfo(chunkId: 5, index: [0]),
    ],
  );
  print('Service: ${retry.reason} (retry chunks)');
  print('  Chunks to retry: ${retry.arrayChunkInfo?.length}');

  // Closing connection
  const closing = ServiceMessage(
    id: 102,
    reason: ServiceReasons.closing,
  );
  print('Service: ${closing.reason} (closing)\n');
}

void demonstratePagination() {
  print('--- Pagination ---');

  // First page
  const page1 = PaginationDto<String, int>(
    cursor: 0,
    pageSize: 3,
    totalItems: 10,
    eof: false,
    items: ['Item 1', 'Item 2', 'Item 3'],
    nextCursor: 3,
  );

  print('Page 1:');
  print('  Items: ${page1.itemCount}/${page1.totalItems}');
  print('  Has more: ${page1.hasMore}');
  print('  Items: ${page1.items}');

  // Second page
  final page2 = page1.copyWith(
    cursor: 3,
    items: ['Item 4', 'Item 5', 'Item 6'],
    nextCursor: 6,
  );

  print('\nPage 2:');
  print('  Items: ${page2.itemCount}/${page2.totalItems}');
  print('  Has more: ${page2.hasMore}');
  print('  Items: ${page2.items}');

  // Last page
  final lastPage = page2.copyWith(
    cursor: 9,
    items: ['Item 10'],
    nextCursor: 10,
    eof: true,
  );

  print('\nLast Page:');
  print('  Items: ${lastPage.itemCount}/${lastPage.totalItems}');
  print('  Has more: ${lastPage.hasMore}');
  print('  Is last: ${lastPage.isLastPage}');
  print('  Items: ${lastPage.items}\n');
}

void demonstrateSignaling() {
  print('--- WebRTC Signaling ---');

  // Create an offer
  const offer = SignalInfoOffer(
    signalData: SignalData(
      type: 'offer',
      sdp: 'v=0\r\no=- 123456789 2 IN IP4 127.0.0.1\r\n...',
    ),
    reusableOffer: ReusableOffer(
      sdp: 'v=0\r\no=- 123456789 2 IN IP4 127.0.0.1\r\n...',
      offerId: 'offer-abc-123',
    ),
  );

  print('Offer:');
  print('  Type: ${offer.signalData.type}');
  print('  Offer ID: ${offer.reusableOffer.offerId}');
  print('  Is Offer: ${offer.isOffer()}');

  // Create an answer
  const answer = SignalInfoAnswer(
    signalData: SignalData(
      type: 'answer',
      sdp: 'v=0\r\no=- 987654321 2 IN IP4 127.0.0.1\r\n...',
    ),
    reusableAnswer: ReusableAnswer(
      answerId: 'answer-xyz-789',
      connectionId: 'conn-456',
      offerId: 'offer-abc-123',
      targetPeer: 'peer-def-456',
    ),
  );

  print('\nAnswer:');
  print('  Type: ${answer.signalData.type}');
  print('  Answer ID: ${answer.reusableAnswer.answerId}');
  print('  Responds to Offer: ${answer.reusableAnswer.offerId}');
  print('  Target Peer: ${answer.reusableAnswer.targetPeer}');
  print('  Is Answer: ${answer.isAnswer()}\n');
}

void demonstrateCallbacks() {
  print('--- Callbacks ---');

  // Define handlers
  void onData(dynamic message) {
    print('  Data received: ${message.data.length} bytes (ID: ${message.id})');
  }

  void onDataFrom(dynamic data, dynamic peerId) {
    print('  Data from $peerId: ${data.length} bytes');
  }

  void onService(dynamic message) {
    print('  Service message: ${message.reason} (ID: ${message.id})');
  }

  // Simulate receiving messages
  print('Simulating message handlers:');
  onData(MessageData(id: 1, data: Uint8List(100)));
  onDataFrom(Uint8List(200), 'peer-123');
  onService(const ServiceMessage(id: 10, reason: ServiceReasons.completed));
  print('');
}
