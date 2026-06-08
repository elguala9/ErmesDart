# NAT Test A — Two Real NATs (no cloud, 100% free, no credit card)

## Goal
Two commands, run on two different machines/networks (e.g. home PC + phone
hotspot 4G/5G). Each peer is a real `OrcErmes` instance behind a real NAT.
Signaling goes through a **public Nostr relay**, address discovery through a
**public STUN server**. They exchange messages following a predetermined
pattern (testData -> ack -> endOfTests), reusing the logic already present in
`packages/ermes_test_docker`.

This is the most authentic NAT-traversal test and costs nothing.

## IMPORTANT — timing constraint (do NOT promise "hours apart")
- Nostr persists the signal, BUT the Ermes signal logically expires after
  `epochTimestampExpireConversation = now + 600s` (10 min), and — more
  importantly — **NAT bindings discovered via STUN live only seconds/minutes**.
- Therefore the two commands can be started **in any order, without
  second-level sync**, but they MUST **overlap in time**.
- Design requirement: each command is a **long-lived rendezvous loop** that
  keeps re-publishing its own fresh signal (to keep the NAT mapping alive) and
  keeps retrying the handshake until the peer shows up. Start A, then start B
  later while A is still running -> OK. Both stopped for hours -> NOT OK.

## Expected result
- Full-cone / restricted-cone NATs (typical home routers): PASS.
- Symmetric NAT / CGNAT (typical mobile 4G/5G): EXPECTED FAIL (no TURN in the
  protocol yet). Documenting this failure is a valid outcome of the test.

## Tasks

### 1. Two standalone CLI binaries (no Docker, no `/output`)
- [ ] Add `packages/ermes_test_docker/bin/nat_peer_a.dart` (initiator, Alice
      role: opens connection, sends the testData sequence, waits for ACKs,
      sends endOfTests).
- [ ] Add `packages/ermes_test_docker/bin/nat_peer_b.dart` (responder, Bob
      role: waits for testData, replies ACK, waits for endOfTests).
- [ ] Reuse `MessageEnvelope`, `DockerTestRunner`, `createDockerOrcErmes`.
- [ ] Replace the hardcoded `/output` dir: print PASS/FAIL summary to stdout
      only (no result file needed for a local manual run).

### 2. Config via env / CLI args (not Docker-only)
- [ ] Keep `DockerErmesConfig.fromEnv()` but document the env vars to set for a
      real internet run:
  - `STUN_HOST=stun.l.google.com`, `STUN_PORT=19302` (public STUN).
  - `NOSTR_RELAYS=wss://relay.damus.io` (or a list, comma-separated).
  - `NOSTR_PUBKEY` / `NOSTR_PRIVKEY` = this side's Nostr keypair.
  - `ALICE_PUBKEY` / `BOB_PUBKEY` = both sides' public keys (shared, fixed test
    identities so each side knows the other's pubkey).
  - `ACCOUNT_ID` = this side's account id (Ethereum-format address expected by
    the book service — verify the exact format required).
- [ ] Provide a small `nat_test_keys.md` (gitignored or committed as test-only)
      with the two fixed keypairs + account ids to copy/paste on both machines.

### 3. Resilient rendezvous loop (the core change vs. the Docker scenario)
- [ ] Wrap `orc.openConnection(peer)` in a retry loop: on failure/timeout,
      re-create/re-publish the signal and retry (e.g. every 30-60s) until
      connected or a max wall-clock (e.g. 30 min) is reached.
- [ ] Verify whether `createSignal` is re-invoked on each retry (fresh STUN
      mapping + fresh expiry). If not, force a re-publish each round.
- [ ] Confirm `_waitForPeerSignal` (60 attempts / 60s in
      `orc_ermes_connection_opener.dart`) is long enough, or extend it.

### 4. The two commands to run
Document the exact invocation on each machine, e.g.:
- [ ] Machine 1 (home PC):
  ```
  dart compile exe packages/ermes_test_docker/bin/nat_peer_a.dart -o nat_peer_a
  STUN_HOST=stun.l.google.com STUN_PORT=19302 \
  NOSTR_RELAYS=wss://relay.damus.io \
  NOSTR_PUBKEY=<A_pub> NOSTR_PRIVKEY=<A_priv> ACCOUNT_ID=<A_acct> \
  ALICE_PUBKEY=<A_pub> BOB_PUBKEY=<B_pub> \
  ./nat_peer_a
  ```
- [ ] Machine 2 (phone hotspot): same but `nat_peer_b` with its own keypair.
- [ ] On Windows document the PowerShell `$env:VAR=...` form too.

### 5. Verify & document
- [ ] Run end-to-end across two real networks; capture stdout from both sides.
- [ ] Record which NAT types passed/failed; confirm symmetric/CGNAT failure.
- [ ] Note the SHSP local port: optionally fix `SHSP_PORT` for easier diagnosis.
