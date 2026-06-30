# GitHub Actions test backlog — index

Subset of the two-PC scenarios (`../`) that can run with **one peer local and
one peer on a GitHub-hosted runner** (or both peers on runners). Each file is a
CI-adapted spec: it keeps the original goal/asserts/metric line and adds the
**Actions wiring** — which side runs on the runner, how the break/manipulation
is produced, and the runner-specific caveats.

## Shared CI harness (already in the repo)
- Workflow `.github/workflows/nat-test.yml` already implements the pattern:
  two jobs `peer-a` / `peer-b`, a `side` input (`a-only` / `b-only` / `both`),
  shared throwaway Nostr identities, public STUN + public Nostr relays.
- **Local + CI run**: dispatch the workflow with `side=b-only` (responder on
  the runner) and run `bin/nat_peer_a.dart` locally with the **same**
  `ALICE_PUBKEY` / `BOB_PUBKEY`, `NOSTR_RELAYS`, `STUN_HOST/PORT`. Swap to
  `a-only` to put the initiator on the runner instead.
- **Scenario selector**: each run step sets `NAT_SCENARIO=<name>`. Today the
  binaries only branch on `network-change` (`isNetworkChangeScenario()` in
  `nat_test_protocol.dart`); every scenario below must extend that same
  env-driven dispatch.
- **Strict contract** (unchanged): exit 0 only if the whole contract passed;
  print `RESULT: PASS/FAIL` and the scenario metric line on one greppable line
  so the job can assert on it.

## Gating risk (validate first)
All scenarios depend on UDP hole-punch succeeding to the runner's Azure NAT.
`nat-test.yml` already proves Azure↔Azure traversal works; **local↔Azure** is a
different NAT pairing — run `encrypted` first as a smoke test. If the punch
fails from your home NAT, none of the others can pass until TURN exists.

## P1 — Disconnection / reconnection (break produced on the LOCAL peer)
- [graceful-reconnect](graceful-reconnect.md) — clean teardown (`disconnectNow`) then re-rendezvous and resume with no message loss
- [peer-restart](peer-restart.md) — hard-kill the local peer and restart it with the same identity; survivor detects the drop and the peer rejoins
- [flap](flap.md) — sub-threshold break (< 8 s `linkSilenceThreshold`); connection must NOT tear down, silence detector must not over-react
- [flap-storm](flap-storm.md) — N break/restore cycles in a row; each reconnects and nothing leaks across cycles
- [long-outage](long-outage.md) — break past the relay signal lifetime (10 min) so it expires; both republish a fresh signal and re-rendezvous — long-running, burns CI minutes

## P2 — Message reliability under churn (break on the LOCAL peer)
- [lossless-reconnect](lossless-reconnect.md) — keep sending sequenced data *during* the outage; after reconnect every sequence number arrives in order (retransmission fills the hole)
- [fragmented-break](fragmented-break.md) — break mid-chunk-stream of a multi-MB payload; message must reassemble correctly after resume
- [gap-detection](gap-detection.md) — induce specific sequence gaps; runner requests the missing IDs and sender resends exactly those (explicit missing-ID path)

## P3 — Encryption / key exchange (pure exchange, no network manipulation)
- [encrypted](encrypted.md) — default ECDH/AES exchange end to end; proves local↔Azure hole-punch + crypto work — **start here (smoke test)**
- [rekey](rekey.md) — rotate the symmetric key mid-session (`ServiceMessageNewKey`); messages before and after decrypt with the right key, no garble at the boundary

## P4 — Load / stress (pure exchange)
- [throughput](throughput.md) — sustain a high message rate (N msg/s for M min) over real NAT; report achieved rate, latency distribution and loss
- [large-payload](large-payload.md) — sweep payload sizes (1 KB → several MB); assert correct reassembly and bounded latency at each size
- [keepalive](keepalive.md) — hold the connection idle with only keepalive traffic, then resume; NAT mapping survives without full re-rendezvous — keep the idle window inside the job timeout

## P5 — Adverse conditions (netem runs ON the Linux runner — it has root)
- [lossy](lossy.md) — inject 5–20% packet loss on the path; delivery still completes via retransmission
- [latency-jitter](latency-jitter.md) — inject high latency and jitter; timeouts/backoff tolerate RTT spikes without false disconnects or duplicate sends
- [mtu-edge](mtu-edge.md) — force a small path MTU; chunk sizing stays under the limit and reassembly is correct, no silent drop of oversized datagrams

## P6 — Multi-peer (one job per peer; more orchestration)
- [star-topology](star-topology.md) — one hub peer with N spokes over real NAT; hub holds N simultaneous connections
- [mesh-3peer](mesh-3peer.md) — three peers in full mesh, each exchanging with the other two; all pairwise connections work with no cross-talk
- [group-churn](group-churn.md) — in a group of 3+, one peer leaves and rejoins while the others keep exchanging; remaining peers unaffected, returning peer re-integrates

## Deliberately excluded (need a real NAT-mapping change or NAT-type control)
`dual-net-change`, `rekey-on-reconnect`, `relay-failover`, `nat-type-matrix` —
a runner cannot swap its NIC / get a fresh NAT mapping, and you do not control
the runner's NAT type. Keep these as two-PC-only (`../`).
