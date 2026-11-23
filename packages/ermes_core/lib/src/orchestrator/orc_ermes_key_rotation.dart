import 'package:cryptdart/cryptdart.dart' show IKeyExchange;
import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';

import '../peer_connection/ermes_pubkey_rotator.dart';
import 'orc_ermes_callbacks.dart';
import 'orc_ermes_connections.dart';
import 'orc_ermes_maintenance.dart';
import 'orc_ermes_passthrough.dart';
import 'orc_pubkey_rotation.dart';
import 'orc_signal_cipher_applier.dart';

/// Encryption public-key rotation of the orchestrator (RFC 8.6): the periodic
/// rotator over every Connection of every family, and the re-derivation on a
/// counterpart's out-of-band rotation.
mixin OrcErmesKeyRotation
    on
        OrcErmesCallbacks,
        OrcErmesPassthrough,
        OrcErmesConnections,
        OrcErmesMaintenance
    implements IOrcErmes<BookData> {
  /// Local key pair, `null` without encryption.
  @protected
  IKeyExchange? get keyExchange;

  /// Whether encryption is on.
  @protected
  bool get encryptionEnabled;

  /// Applier deriving the per-Connection session keys.
  @protected
  OrcSignalCipherApplier? get cipherApplier;

  /// Newest accepted signal per counterpart.
  @protected
  IErmesSignalLastSeenStore get signalLastSeen;

  /// Periodic rotator; started by the first [openConnection], `null` when
  /// the key pair cannot be rotated.
  late final ErmesPubKeyRotator? _pubKeyRotator = buildOrcPubKeyRotator(
    OrcPubKeyRotationInput(
      keyExchange: keyExchange,
      applier: cipherApplier,
      enableEncryption: encryptionEnabled,
      services: () => [
        for (final held in connections.values)
          for (final member in held.members) member.service,
      ],
      republish: republishOwnSignals,
    ),
  );

  /// Rotates the local encryption key pair now instead of waiting for the
  /// periodic timer: announces it on every Connection, re-derives the
  /// session keys and re-publishes our signal. No-op without rotation.
  Future<void> rotatePublicKey() async => _pubKeyRotator?.rotate();

  @override
  Future<void> openConnection(IdPeer peer) async {
    _pubKeyRotator?.start();
    await super.openConnection(peer);
  }

  @override
  Future<void> onAlreadyConnected(IdPeer peer) async {
    await rederiveOnRepublishedSignal(
        signalingServer, cipherApplier, signalLastSeen, peer);
  }

  @override
  Future<void> destroy({bool force = false}) async {
    _pubKeyRotator?.dispose();
    await super.destroy(force: force);
  }
}
