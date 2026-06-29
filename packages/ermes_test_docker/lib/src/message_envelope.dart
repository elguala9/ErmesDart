import 'dart:convert';
import 'dart:typed_data';

enum DockerMsgType {
  ready,
  testData,
  ack,
  disconnectNow,
  endOfTests,

  /// Carries a peer's ECDH public key (in [MessageEnvelope.testName]) during
  /// the encrypted-scenario handshake.
  keyExchange,

  /// Plaintext confirmation that the sender has registered its decryption
  /// cipher, so the peer may safely start encrypting toward it.
  decryptReady,

  /// Carries a freshly rotated AES key (hex, in [MessageEnvelope.testName])
  /// for the rekey scenario; the receiver registers it as a decrypt cipher.
  newKey,

  /// Liveness probe sent by [rendezvous] to confirm the punched channel
  /// actually carries data; the peer's liveness handler echoes a
  /// [rendezvousPong]. Scenario handlers ignore both.
  rendezvousPing,

  /// Reply to a [rendezvousPing], proving a full round trip (our ping reached
  /// the peer and its reply reached us) so the rendezvous is genuinely live.
  rendezvousPong,
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

  /// Compact one-line summary for verbose test logs: type, sequence,
  /// test name and a hex preview of the payload.
  String describe() {
    final parts = <String>['type=${type.name}'];
    if (seq != null) {
      parts.add('seq=$seq');
    }
    if (testName != null) {
      parts.add('test=$testName');
    }
    if (payload != null) {
      parts.add('payload=${payload!.length}B[${_hexPreview(payload!)}]');
    }
    return parts.join(' ');
  }

  static String _hexPreview(Uint8List bytes) {
    const maxBytes = 16;
    final shown = bytes.length <= maxBytes ? bytes : bytes.sublist(0, maxBytes);
    final hex =
        shown.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    return bytes.length <= maxBytes ? hex : '$hex …';
  }
}
