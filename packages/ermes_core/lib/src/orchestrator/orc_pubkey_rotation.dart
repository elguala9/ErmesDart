import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_cipher/ermes_cipher.dart';
import 'package:iermes/iermes.dart';

import '../peer_connection/ermes_pubkey_rotator.dart';
import 'orc_signal_cipher_applier.dart';

/// Inputs wiring an [ErmesPubKeyRotator] into `OrcErmes`.
class OrcPubKeyRotationInput {
  /// Creates the input.
  const OrcPubKeyRotationInput({
    required this.keyExchange,
    required this.applier,
    required this.enableEncryption,
    required this.services,
    required this.republish,
  });

  /// Local key pair; rotation needs a replaceable [ECDHKeyExchangeService].
  final IKeyExchange? keyExchange;

  /// Applier re-deriving every Connection's session keys.
  final OrcSignalCipherApplier? applier;

  /// Whether encryption is on (no key to rotate otherwise).
  final bool enableEncryption;

  /// Services of every live Connection.
  final Iterable<IErmesService> Function() services;

  /// Re-publishes our signal (broadcast and per peer).
  final Future<void> Function() republish;
}

/// Builds the RFC 8.6 rotator, or `null` when encryption is off or the key
/// pair cannot be replaced in place.
ErmesPubKeyRotator? buildOrcPubKeyRotator(OrcPubKeyRotationInput input) {
  final exchange = input.keyExchange;
  final applier = input.applier;
  if (!input.enableEncryption ||
      applier == null ||
      exchange is! ECDHKeyExchangeService) {
    return null;
  }
  return ErmesPubKeyRotatorFactory.create(
    ErmesPubKeyRotatorInput(
      renewKeyPair: () async {
        await exchange.generateKeyPair();
        return exchange.publicKey;
      },
      services: input.services,
      rederive: applier.reapplyAll,
      republish: input.republish,
    ),
  );
}

/// Reads [peer]'s current signal and, when it re-publishes the same
/// IdSignaling with a new public key (RFC 8.6 out-of-band rotation),
/// re-derives the session keys. Older signals are ignored. Best-effort:
/// a relay read failure is swallowed. Returns whether keys were re-derived.
Future<bool> rederiveOnRepublishedSignal(
  IErmesSignalingServer server,
  OrcSignalCipherApplier? applier,
  IErmesSignalLastSeenStore lastSeen,
  IdPeer peer,
) async {
  if (applier == null) {
    return false;
  }
  try {
    final signal = await server.getSignal(peer, forceRefresh: true);
    if (lastSeen.isRegression(peer, signal)) {
      return false;
    }
    final changed = applier.applyIfRotated(peer, signal);
    if (changed) {
      lastSeen.record(peer, signal);
    }
    return changed;
  } on Object {
    return false;
  }
}
