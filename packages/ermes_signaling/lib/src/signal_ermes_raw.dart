import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:cryptdart/types/crypto_algorithm.dart';
import 'package:iermes/iermes.dart';

import '../ermes_signaling.dart';
import 'ermes_signal_type.dart';

/// Implementation of ISignalErmesRaw with String as EncryptionType
@includeInBarrelFile
class SignalErmesRaw implements ISignalErmesRaw<CryptoAlgorithm> {
  /// Creates a SignalErmesRaw instance
  SignalErmesRaw({
    required this.signal,
    required this.isEncrypted,
    this.encryptionType,
  });

  @override
  String signal;

  @override
  bool isEncrypted;

  @override
  CryptoAlgorithm? encryptionType;

  /// Parse a raw signal string
  ///
  /// Format expected: "signal|isEncrypted|encryptionType"
  @override
  void fromString(String signalErmesRawString) {
    final parts = signalErmesRawString.split('|');
    if (parts.length >= 2) {
      signal = parts[0];
      isEncrypted = parts[1].toLowerCase() == 'true';

      if (parts.length > 2) {
        final encryptionTypeStr = parts[2];
        encryptionType = CryptoAlgorithm.allAlgorithms
            .cast<CryptoAlgorithm?>()
            .firstWhere(
              (e) => e != null && e.toString().endsWith(encryptionTypeStr),
              orElse: () => null,
            );
      } else {
        encryptionType = null;
      }
    }
  }

  /// Convert to raw signal string
  ///
  /// Returns format: "signal|isEncrypted|encryptionType"
  @override
  String toString() => '$signal|$isEncrypted|$encryptionType';

  /// Extract the unencrypted signal
  ///
  /// Returns the ISignalErmes from the raw signal data
  @override
  ISignalErmes getSignal() => SignalErmes(
    publicKey: '',
    ipv6: '',
    ipv6Port: '',
    ipv4: '',
    ipv4Port: '',
    epochTimestampStartConversation: 0,
    secondsIntervalWindow: 0,
    epochTimestampExpireConversation: 0,
  );
}
