import 'dart:io';

import 'ermes_setup.dart';

/// Which side of the NAT test this process plays.
enum NatRole { a, b }

/// Thrown when the NAT-test environment is missing or malformed.
///
/// Carries every problem found so a CI log shows them all at once
/// instead of failing one variable at a time.
class NatConfigException implements Exception {
  NatConfigException(this.problems);

  final List<String> problems;

  @override
  String toString() =>
      'NatConfigException: invalid NAT-test environment:\n'
      '${problems.map((p) => '  - $p').join('\n')}';
}

/// Strictly-validated configuration for the two NAT-test binaries.
///
/// Unlike [DockerErmesConfig.fromEnv], this never substitutes silent
/// defaults for identity material: any missing or malformed variable
/// makes [fromEnvStrict] throw, so a misconfigured CI job fails loudly
/// instead of running with placeholder keys.
class NatConfig {
  NatConfig({
    required this.role,
    required this.selfPubkey,
    required this.selfPrivkey,
    required this.peerPubkey,
    required this.accountId,
    required this.stunHost,
    required this.stunPort,
    required this.relayUrls,
    required this.shspPort,
  });

  /// Reads every NAT-test variable from the environment and validates it.
  ///
  /// Throws [NatConfigException] listing *all* problems found.
  factory NatConfig.fromEnvStrict(NatRole role) {
    final env = Platform.environment;
    final problems = <String>[];

    final privkey = _hex64(env['NOSTR_PRIVKEY'], 'NOSTR_PRIVKEY', problems);
    final pubkey = _hex64(env['NOSTR_PUBKEY'], 'NOSTR_PUBKEY', problems);
    final alice = _hex64(env['ALICE_PUBKEY'], 'ALICE_PUBKEY', problems);
    final bob = _hex64(env['BOB_PUBKEY'], 'BOB_PUBKEY', problems);
    final stunHost = _required(env['STUN_HOST'], 'STUN_HOST', problems);
    final stunPort = _port(env['STUN_PORT'], 'STUN_PORT', problems);
    final relays = _relays(env['NOSTR_RELAYS'], problems);
    final shspPort = _optionalPort(env['SHSP_PORT'], 'SHSP_PORT', problems);

    final expectedSelf = role == NatRole.a ? alice : bob;
    final peer = role == NatRole.a ? bob : alice;
    final selfMismatch =
        pubkey.isNotEmpty && expectedSelf.isNotEmpty && pubkey != expectedSelf;
    if (selfMismatch) {
      problems.add(
        'NOSTR_PUBKEY ($pubkey) does not match the '
        '${role == NatRole.a ? 'ALICE' : 'BOB'}_PUBKEY for role '
        '${role.name.toUpperCase()} ($expectedSelf)',
      );
    }
    if (pubkey.isNotEmpty && peer.isNotEmpty && pubkey == peer) {
      problems.add(
        'NOSTR_PUBKEY equals the peer pubkey; the two sides '
        'must use distinct identities',
      );
    }

    if (problems.isNotEmpty) {
      throw NatConfigException(problems);
    }

    return NatConfig(
      role: role,
      selfPubkey: pubkey,
      selfPrivkey: privkey,
      peerPubkey: peer,
      accountId: env['ACCOUNT_ID']?.isNotEmpty ?? false
          ? env['ACCOUNT_ID']!
          : pubkey,
      stunHost: stunHost,
      stunPort: stunPort,
      relayUrls: relays,
      shspPort: shspPort,
    );
  }

  final NatRole role;
  final String selfPubkey;
  final String selfPrivkey;
  final String peerPubkey;
  final String accountId;
  final String stunHost;
  final int stunPort;
  final List<String> relayUrls;
  final int? shspPort;

  /// Bridges to the existing OrcErmes setup used by the Docker harness.
  DockerErmesConfig toDockerConfig() => DockerErmesConfig(
    pubkey: selfPubkey,
    privkey: selfPrivkey,
    accountId: accountId,
    stunHost: stunHost,
    stunPort: stunPort,
    shspPort: shspPort,
    // Role A talks to B and vice-versa; charlie is unused here but the
    // shared config requires a value, so reuse the peer pubkey.
    alicePubkey: role == NatRole.a ? selfPubkey : peerPubkey,
    bobPubkey: role == NatRole.a ? peerPubkey : selfPubkey,
    charliePubkey: peerPubkey,
    relayUrls: relayUrls,
  );

  static String _required(String? v, String name, List<String> problems) {
    if (v == null || v.isEmpty) {
      problems.add('$name is not set');
      return '';
    }
    return v;
  }

  static String _hex64(String? v, String name, List<String> problems) {
    final s = _required(v, name, problems);
    if (s.isNotEmpty && !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(s)) {
      problems.add('$name must be 64 hex chars, got "${_clip(s)}"');
      return '';
    }
    return s;
  }

  static int _port(String? v, String name, List<String> problems) {
    final s = _required(v, name, problems);
    if (s.isEmpty) {
      return 0;
    }
    final p = int.tryParse(s);
    if (p == null || p < 1 || p > 65535) {
      problems.add('$name must be an integer in 1..65535, got "$s"');
      return 0;
    }
    return p;
  }

  static int? _optionalPort(String? v, String name, List<String> problems) {
    if (v == null || v.isEmpty) {
      return null;
    }
    final p = int.tryParse(v);
    if (p == null || p < 1 || p > 65535) {
      problems.add(
        '$name, when set, must be an integer in 1..65535, '
        'got "$v"',
      );
      return null;
    }
    return p;
  }

  static List<String> _relays(String? v, List<String> problems) {
    final s = _required(v, 'NOSTR_RELAYS', problems);
    if (s.isEmpty) {
      return const [];
    }
    final urls = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final bad = urls.where((u) => !u.startsWith('wss://')).toList();
    if (bad.isNotEmpty) {
      problems.add(
        'NOSTR_RELAYS must be comma-separated wss:// URLs; '
        'offending: ${bad.join(', ')}',
      );
    }
    return urls.toList();
  }

  static String _clip(String s) =>
      s.length <= 12 ? s : '${s.substring(0, 12)}…';
}
