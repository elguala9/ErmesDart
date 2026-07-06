// Prints two freshly generated Nostr identities (alice + bob) in shell-eval
// form, one VAR=value per line. Used by scripts/lib/github-nat-driver.sh to
// give every NAT-scenario dispatch its own throwaway keypair: signals from a
// PREVIOUS run (same authors, 10-minute TTL on the relays) can otherwise win
// the relay race and leave both peers punching dead ports.
// stdout is the transport; printing is intentional.
// ignore_for_file: avoid_print

import 'package:nostr_signaling/nostr_signaling.dart';

void main() {
  final alice = NostrKeys.generate();
  final bob = NostrKeys.generate();
  print('ALICE_PUBKEY=${alice.publicKey}');
  print('NOSTR_ALICE_PRIVKEY=${alice.privateKey}');
  print('BOB_PUBKEY=${bob.publicKey}');
  print('BOB_PRIVKEY=${bob.privateKey}');
}
