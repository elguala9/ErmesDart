# TODO — Complex two-PC integration tests

Backlog of richer cross-machine scenarios for `OrcErmes`, to run on two (or
more) real PCs on different networks. Builds on the existing harness:

- **Selector**: `NAT_SCENARIO=<name>` env var (see `nat_test_protocol.dart`).
- **Engines**: `NatHeartbeatInitiator` / `NatHeartbeatResponder` (sustained
  heartbeat) and the one-shot batch in `nat_peer_a.dart` / `nat_peer_b.dart`.
- **Protocol**: `MessageEnvelope` / `DockerMsgType` (`ready`, `testData`,
  `ack`, `disconnectNow`, `endOfTests`). `disconnectNow` is defined but not
  yet exercised — several items below give it a use.
- **Drivers**: `scripts/run-nat-test-pc.sh` (two machines), `scripts/run-net-change-test-compose.sh`
  (containerised net swap), `.github/workflows/nat-test.yml` (Azure↔Azure).

Every new scenario must keep the existing **strict** contract: exit 0 only if
the whole contract passed; print `RESULT: PASS/FAIL` and metrics on one
greppable line so the driver scripts can assert on it.

---

## ✅ Already covered (baseline)

- [x] One-shot send + ACK + `endOfTests` over real NAT (default scenario).
- [x] Network-change handoff with auto-reconnect + reconnect-time / lost-message
      metrics (`NAT_SCENARIO=network-change`).
- [x] Two-machine driver script and GitHub Actions automation.

---

## 🔴 Priority 1 — Disconnection / reconnection variants

The core reconnect path is `OrcConnectionOpener.open()` → `handlePeerDisconnect()`
→ `openConnection()` (re-rendezvous). These scenarios stress it from different
break causes.

- [ ] **Graceful disconnect + reconnect** (`NAT_SCENARIO=graceful-reconnect`)
  - Initiator sends `disconnectNow`, both sides tear down the SHSP connection
    cleanly, then re-rendezvous and resume the heartbeat.
  - Asserts: clean teardown (no error thrown), reconnect within budget, zero
    message loss after resume. Uses the already-defined `disconnectNow` type.

- [ ] **Peer process crash + restart** (`NAT_SCENARIO=peer-restart`)
  - Hard-kill the responder process mid-exchange (SIGKILL), restart it with the
    **same identity**, verify the initiator detects the drop and the restarted
    peer rejoins and resumes.
  - Asserts: initiator's `handlePeerDisconnect` fires; new connection
    established; heartbeat resumes. Measure rejoin time.

- [ ] **Long outage beyond signal expiry** (`NAT_SCENARIO=long-outage`)
  - Break the link for > `epochTimestampExpireConversation` (10 min) so the
    relay signal expires, then restore. Verifies both peers republish a fresh
    signal and re-rendezvous (no stale-signal dead-port punch).
  - Asserts: reconnect succeeds after the stale signal is gone; resume verified.

- [ ] **Brief flap (sub-threshold)** (`NAT_SCENARIO=flap`)
  - Drop the link for less than `linkSilenceThreshold` (8 s) and restore.
  - Asserts: the connection is NOT torn down (no spurious reconnect); heartbeat
    continues with at most a couple of missed beats, then catches up.

- [ ] **Both peers change network simultaneously** (`NAT_SCENARIO=dual-net-change`)
  - Swap both sides' networks at the same time (worst case: two new mappings).
  - Asserts: rendezvous still converges; resume within an extended budget.

- [ ] **Repeated reconnect (flap storm)** (`NAT_SCENARIO=flap-storm`)
  - Break/restore the link N times in a row.
  - Asserts: each cycle reconnects; no resource/listener leak (stable memory,
    no duplicated connections in `getConnections()`); backoff behaves.

---

## 🟠 Priority 2 — Message reliability under churn

Exercises `ermes_message_control` (retransmission, gap detection) across a real
break instead of in-process tests.

- [ ] **Zero-loss across outage** (`NAT_SCENARIO=lossless-reconnect`)
  - Keep sending sequenced `testData` *during* the outage; after reconnect the
    receiver must have **every** sequence number, delivered in order.
  - Asserts: no gaps, retransmission fills the hole, final set complete.

- [ ] **Large message interrupted mid-transfer** (`NAT_SCENARIO=fragmented-break`)
  - Send a multi-MB payload (forces chunking in `ErmesService`), break the link
    while chunks are in flight, restore.
  - Asserts: message reassembles correctly after resume (chunk handler +
    retransmission); checksum of received payload matches.

- [ ] **Out-of-order / gap detection** (`NAT_SCENARIO=gap-detection`)
  - Induce gaps (drop specific sequence numbers via the flap) and verify the
    receiver requests the missing IDs and the sender resends them.
  - Asserts: missing-message request path and threshold-based resend observed.

---

## 🟡 Priority 3 — Encryption / key exchange across machines

Currently cipher is covered by in-process tests; these validate it over real
NAT, where timing and reconnection interact with key state.

- [ ] **ECDH handshake over real NAT** (`NAT_SCENARIO=encrypted`)
  - Run the default exchange with encryption enabled end to end.
  - Asserts: payloads are ciphertext on the wire; both sides decrypt correctly.

- [ ] **Key rotation mid-session** (`NAT_SCENARIO=rekey`)
  - Push a new key (`ServiceMessageNewKey`) during a live heartbeat.
  - Asserts: messages before/after the rotation decrypt with the right key; no
    dropped/garbled messages at the boundary.

- [ ] **Re-key after reconnect** (`NAT_SCENARIO=rekey-on-reconnect`)
  - Verify cipher state survives (or is correctly re-negotiated after) a network
    change. Catches the case where reconnect loses key material.

---

## 🟢 Priority 4 — Load / stress

- [ ] **Sustained high-throughput** (`NAT_SCENARIO=throughput`)
  - N messages/second for M minutes; report achieved rate, latency
    distribution, loss.
  - Asserts: sustained rate ≥ target, loss == 0, no memory growth.

- [ ] **Large payload matrix** (`NAT_SCENARIO=large-payload`)
  - Sweep payload sizes (1 KB → several MB) and assert correct reassembly and
    bounded latency at each size.

- [ ] **Long-lived idle connection** (`NAT_SCENARIO=keepalive`)
  - Hold the connection idle for a long period (e.g. 30+ min) with only
    keepalive traffic, then resume the exchange.
  - Asserts: NAT mapping survives (or is refreshed); exchange resumes without a
    full re-rendezvous.

---

## 🔵 Priority 5 — Adverse network conditions

Inject impairment with `tc netem` (Linux) on one or both peers.

- [ ] **Packet loss** (`NAT_SCENARIO=lossy`) — e.g. 5–20% loss; assert delivery
      still completes via retransmission.
- [ ] **High latency / jitter** — assert timeouts/backoff tolerate RTT spikes.
- [ ] **Relay outage / failover** — kill one relay in `NOSTR_RELAYS` mid-session;
      assert rendezvous/reconnect still works via the remaining relays.
- [ ] **MTU / fragmentation edge** — small MTU on the path; assert chunk sizing
      stays under the limit and reassembly is correct.

---

## ⚪ Priority 6 — Multi-peer topologies (3+ machines)

Extends beyond two PCs. There are already `alice_main.dart` / `bob_main.dart` /
`charlie_main.dart` to build on.

- [ ] **Three-peer mesh across machines** — each pair maintains a live exchange;
      assert all three pairwise connections and zero cross-talk.
- [ ] **Star topology across machines** — one hub, N spokes on separate PCs;
      mirror the in-process star test over real NAT.
- [ ] **Peer churn in a group** — one peer leaves/rejoins while the others keep
      exchanging; assert the rest are unaffected.

---

## NAT-type matrix (cross-cutting — track results, not code)

Run the relevant scenarios across NAT combinations and record outcomes in
`NAT_TEST.md`:

- [ ] cone ↔ cone (expected PASS)
- [ ] cone ↔ symmetric
- [ ] symmetric ↔ symmetric (expected FAIL until TURN)
- [ ] CGNAT / mobile 4G-5G (expected FAIL until TURN)
- [ ] IPv6 ↔ IPv6 and IPv4 ↔ IPv6 paths

---

## Implementation notes

- **One scenario = one `NAT_SCENARIO` value**, dispatched in `nat_peer_a.dart`
  and `nat_peer_b.dart` next to the existing `isNetworkChangeScenario()` check.
  Add the constant to `NatTestProtocol` with its own timing budgets.
- **Reuse the heartbeat engines** where a live connection is needed; only the
  break trigger and the assertion differ between most reconnect scenarios.
- **Driver scripts**: the container swap in `run-net-change-test-compose.sh` already
  models breaks; parameterise it (break duration, number of cycles, kill vs
  swap) instead of forking a new script per scenario.
- **Metrics**: extend `ReconnectMetrics.describe()` style one-liners per
  scenario so drivers/CI assert on stable, greppable output.
- **Fresh identities** per run (or wait out the 10-min signal expiry) to avoid
  stale-signal interference — except the `long-outage` scenario, which tests
  exactly that expiry.
