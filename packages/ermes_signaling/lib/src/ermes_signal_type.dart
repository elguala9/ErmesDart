import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

@includeInBarrelFile
class SignalErmes implements ISignalErmes {
  SignalErmes({
    required this.publicKey,
    required this.ipv6,
    required this.ipv6Port,
    required this.ipv4,
    required this.ipv4Port,
    required this.epochTimestampStartConversation,
    // for how much a window is open
    this.secondsIntervalWindow = 10,
    required this.epochTimestampExpireConversation,
    // every how much seconds the window get opened
    this.secondsIntervalOpening = 60
  });

  // Factory constructor per creare da stringa
  factory SignalErmes.fromString(String signalString) {
    final signal = SignalErmes(
      publicKey: '',
      ipv6: '',
      ipv6Port: '',
      ipv4: '',
      ipv4Port: '',
      epochTimestampStartConversation: 0,
      secondsIntervalWindow: 0,
      epochTimestampExpireConversation: 0,
      secondsIntervalOpening: 0
    )..fromString(signalString);
    return signal;
  }
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
      '$epochTimestampExpireConversation';

  @override
  void fromString(String signalString) {
    final parts = signalString.split('|');
    if (parts.length != 8) {
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
}
