import 'dart:convert';
import 'dart:typed_data';

enum DockerMsgType {
  ready,
  testData,
  ack,
  disconnectNow,
  endOfTests,
}

class MessageEnvelope {
  const MessageEnvelope({
    required this.type,
    this.testName,
    this.seq,
    this.payload,
  });

  factory MessageEnvelope.decode(Uint8List bytes) {
    final map = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final type = DockerMsgType.values.firstWhere(
      (e) => e.name == map['type'] as String,
    );
    return MessageEnvelope(
      type: type,
      testName: map['test'] as String?,
      seq: map['seq'] as int?,
      payload: map['payload'] != null
          ? base64.decode(map['payload'] as String)
          : null,
    );
  }

  final DockerMsgType type;
  final String? testName;
  final int? seq;
  final Uint8List? payload;

  Uint8List encode() {
    final map = <String, Object?>{
      'type': type.name,
      if (testName != null) 'test': testName,
      if (seq != null) 'seq': seq,
      if (payload != null) 'payload': base64.encode(payload!),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(map)));
  }
}
