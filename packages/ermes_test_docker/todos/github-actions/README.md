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
- [graceful-reconnect](graceful-reconnect.md)
- [peer-restart](peer-restart.md)
- [flap](flap.md)
- [flap-storm](flap-storm.md)
- [long-outage](long-outage.md) — long-running, burns CI minutes

## P2 — Message reliability under churn (break on the LOCAL peer)
- [lossless-reconnect](lossless-reconnect.md)
- [fragmented-break](fragmented-break.md)
- [gap-detection](gap-detection.md)

## P3 — Encryption / key exchange (pure exchange, no network manipulation)
- [encrypted](encrypted.md) — **start here (smoke test)**
- [rekey](rekey.md)

## P4 — Load / stress (pure exchange)
- [throughput](throughput.md)
- [large-payload](large-payload.md)
- [keepalive](keepalive.md) — keep the idle window inside the job timeout

## P5 — Adverse conditions (netem runs ON the Linux runner — it has root)
- [lossy](lossy.md)
- [latency-jitter](latency-jitter.md)
- [mtu-edge](mtu-edge.md)

## P6 — Multi-peer (one job per peer; more orchestration)
- [star-topology](star-topology.md)
- [mesh-3peer](mesh-3peer.md)
- [group-churn](group-churn.md)

## Deliberately excluded (need a real NAT-mapping change or NAT-type control)
`dual-net-change`, `rekey-on-reconnect`, `relay-failover`, `nat-type-matrix` —
a runner cannot swap its NIC / get a fresh NAT mapping, and you do not control
the runner's NAT type. Keep these as two-PC-only (`../`).
