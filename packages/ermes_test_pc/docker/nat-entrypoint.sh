#!/bin/sh
# Entrypoint for the single NAT-test image. Picks the peer role from the first
# argument (a = initiator, b = responder) and fills in the public throwaway
# test identity plus public STUN/relay defaults for any variable the caller
# did not override. Override anything by passing -e VAR=... to `docker run`.
set -eu

ROLE="${1:-${ROLE:-}}"

# Shared fixed test identities (throwaway — NOT real keys). Both sides must
# agree on these two public keys; they are already public in the repo.
ALICE_PUBKEY="${ALICE_PUBKEY:-b92ad53e9350444f5572b4ffdc51a9839161729b0f5a62e68a3694c78d3dc4c5}"
BOB_PUBKEY="${BOB_PUBKEY:-40f72d5b56f8fcda629d4fd9e046038480cc71aaee01b3a2fc524aba6803dcac}"
export ALICE_PUBKEY BOB_PUBKEY

# Public infrastructure defaults (no account, no credit card).
export STUN_HOST="${STUN_HOST:-stun.l.google.com}"
export STUN_PORT="${STUN_PORT:-19302}"
export NOSTR_RELAYS="${NOSTR_RELAYS:-wss://nos.lol,wss://relay.damus.io,wss://nostr-pub.wellorder.net,wss://relay.primal.net}"

case "$ROLE" in
  a|A|alice|peer-a)
    export NOSTR_PUBKEY="${NOSTR_PUBKEY:-$ALICE_PUBKEY}"
    export NOSTR_PRIVKEY="${NOSTR_PRIVKEY:-baeed075852a757626e2bae3220c915ec43bcdc81343f83b0f50e3a933063d6c}"
    export ACCOUNT_ID="${ACCOUNT_ID:-$ALICE_PUBKEY}"
    exec /app/peer_a
    ;;
  b|B|bob|peer-b)
    export NOSTR_PUBKEY="${NOSTR_PUBKEY:-$BOB_PUBKEY}"
    export NOSTR_PRIVKEY="${NOSTR_PRIVKEY:-187f26af502a4b1dff9c80ab7798ffaace92c3db4ce85301300558ae02a3310e}"
    export ACCOUNT_ID="${ACCOUNT_ID:-$BOB_PUBKEY}"
    exec /app/peer_b
    ;;
  *)
    echo "Usage: docker run --rm --network host <image> {a|b}" >&2
    echo "  a = initiator (Alice role), b = responder (Bob role)" >&2
    echo "Override NOSTR_*, STUN_*, NOSTR_RELAYS or ACCOUNT_ID with -e." >&2
    exit 2
    ;;
esac
