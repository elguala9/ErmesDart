import 'package:iermes/iermes.dart';

/// Concrete signal describing a peer's reachable endpoints, public key and
/// conversation timing window, serializable to and from a string.
class SignalErmes implements ISignalErmes {
  /// Creates a signal with the given endpoints, key and timing parameters.
  ///
  /// [idSignaling] is the publisher's IdSignaling (RFC section 6.1); it must
  /// not contain the `|` field separator.
  SignalErmes({
    required this.idSignaling,
    required this.publicKey,
    required this.ipv6,
    required this.ipv6Port,
    required this.ipv4,
    required this.ipv4Port,
    required this.epochTimestampStartConversation,
    required this.epochTimestampExpireConversation,
    // for how much a window is open
    this.secondsIntervalWindow = 10,
    // every how much seconds the window get opened
    this.secondsIntervalOpening = 60,
  }) {
    _checkIdSignaling(idSignaling);
  }

  // Factory constructor per creare da stringa
  /// Parses a signal from its pipe-separated string representation.
  factory SignalErmes.fromString(String signalString) {
    final signal = SignalErmes(
      idSignaling: '',
      publicKey: '',
      ipv6: '',
      ipv6Port: '',
      ipv4: '',
      ipv4Port: '',
      epochTimestampStartConversation: 0,
      secondsIntervalWindow: 0,
      epochTimestampExpireConversation: 0,
      secondsIntervalOpening: 0,
    )..fromString(signalString);
    return signal;
  }
  /// Number of `|` separated fields of the wire format.
  static const int fieldCount = 10;

  @override
  String idSignaling;

  @override
  String publicKey;

  @override
  String ipv6;

  @override
  String ipv6Port;

  @override
  String ipv4;

  @override
  String ipv4Port;

  @override
  int epochTimestampStartConversation;

  @override
  int secondsIntervalWindow;

  @override
  int epochTimestampExpireConversation;

  @override
  String toString() =>
      '$publicKey|$ipv6|$ipv6Port|$ipv4|$ipv4Port|'
      '$epochTimestampStartConversation|$secondsIntervalWindow|'
      '$epochTimestampExpireConversation|$secondsIntervalOpening|$idSignaling';

  @override
  void fromString(String signalString) {
    final parts = signalString.split('|');
    // RFC section 6.1: a signal MUST carry the publisher's IdSignaling, so
    // legacy 8/9-field signals are rejected as unparseable.
    if (parts.length != fieldCount || parts[9].isEmpty) {
      throw ArgumentError('Invalid signal string format');
    }

    publicKey = parts[0];
    ipv6 = parts[1];
    ipv6Port = parts[2];
    ipv4 = parts[3];
    ipv4Port = parts[4];
    epochTimestampStartConversation = int.parse(parts[5]);
    secondsIntervalWindow = int.parse(parts[6]);
    epochTimestampExpireConversation = int.parse(parts[7]);
    secondsIntervalOpening = int.parse(parts[8]);
    idSignaling = parts[9];
  }

  @override
  bool isExpired() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 >
      epochTimestampExpireConversation;

  @override
  String get signal => toString();

  @override
  set signal(String value) {
    fromString(value);
  }

  @override
  int secondsIntervalOpening;

  static void _checkIdSignaling(String id) {
    if (id.contains('|')) {
      throw ArgumentError.value(id, 'idSignaling', 'must not contain "|"');
    }
  }
}
