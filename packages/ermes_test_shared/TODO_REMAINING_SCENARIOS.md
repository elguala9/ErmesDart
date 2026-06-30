# Remaining cross-network scenarios — master TODO

Single tracking sheet for the scenario families that still need wiring across
**both** runtimes that drive the shared engines:

- **GitHub Actions** (`ermes_test_actions`) — one peer local, one on a runner.
  Per-scenario spec: `packages/ermes_test_actions/todos/github-actions/`.
- **Two-PC** (`ermes_test_pc`) — both peers on real machines.
  Per-scenario spec: `packages/ermes_test_pc/todos/`.

Every scenario is selected at runtime with `NAT_SCENARIO=<id>` and runs the same
engine in `ermes_test_shared/lib/src/`. A scenario is "done" only when the engine
exists, the dispatch in `bin/nat_peer_a.dart` / `bin/nat_peer_b.dart` routes to
it, and both runtimes can launch it (Actions `.yml` + `run-test-github-*.sh`,
PC todo).

Legend — **Status**: ⬜ not started · 🟡 in progress · ✅ done · 📝 todo-only.

## Done before this effort
- **P1** — graceful-reconnect, peer-restart, flap, flap-storm, long-outage ✅
- **P3** — encrypted, rekey ✅

## P2 — Message reliability under churn (break on the LOCAL peer)
Engine: `nat_p2_protocol.dart`, `nat_p2_initiator.dart`, `nat_p2_responder.dart`.

| Scenario | id | Actions | PC | Notes |
|---|---|---|---|---|
| lossless-reconnect | `lossless-reconnect` | ✅ | ✅ | sender keeps emitting sequenced data through an in-process break; receiver must hold every seq in order |
| fragmented-break | `fragmented-break` | ✅ | ✅ | one multi-MB payload (forces chunking), link broken mid-stream, checksum must match after resume |
| gap-detection | `gap-detection` | ✅ | ✅ | initiator skips targeted seqs; responder requests the exact missing IDs (`requestMissing`); only those are resent |

## P4 — Load / stress (pure exchange, no network manipulation)
Engine: `nat_load_protocol.dart`, `nat_load_initiator.dart`, `nat_load_responder.dart`.

| Scenario | id | Actions | PC | Notes |
|---|---|---|---|---|
| throughput | `throughput` | ✅ | ✅ | sustain `TARGET_RATE` msg/s for `DURATION`; report achieved rate + p50/p99 latency + loss |
| large-payload | `large-payload` | ✅ | ✅ | sweep `SIZES`; checksum each reassembled payload, track max latency |
| keepalive | `keepalive` | ✅ | ✅ | idle for `IDLE_DURATION` (keepalive only), then resume WITHOUT a full re-rendezvous |

## P5 — Adverse conditions (netem / MTU applied EXTERNALLY)
Engine: reuses the P4 reliable exchange (`nat_load_*`). The degradation is applied
by the **workflow** (`tc qdisc` / `ip link set mtu` on the Linux runner) or by the
operator on the PC side — the Dart engine only asserts the exchange still completes.

| Scenario | id | Actions | PC | Notes |
|---|---|---|---|---|
| lossy | `lossy` | ✅ | ✅ | `tc netem loss ${LOSS_PCT}%` on the runner; full sequence still delivered, gaps=0 |
| latency-jitter | `latency-jitter` | ✅ | ✅ | `tc netem delay ${DELAY_MS}ms ${JITTER_MS}ms`; no false disconnect, no duplicate delivery |
| mtu-edge | `mtu-edge` | ✅ | ✅ | `ip link set mtu ${MTU}`; no oversized datagram, reassembly correct |

## P6 — Multi-peer (3+ peers) — 📝 TODO ONLY this pass
Needs brand-new rendezvous-capable peer binaries: the existing
`ermes_test_docker` alice/bob/charlie bins use a fixed Docker network, **not** the
public-NAT rendezvous, so they cannot run over CI / two real NATs. Plan:

1. Add `bin/nat_peer_c.dart` (and generalise A/B) so each peer reads a list of
   peer pubkeys and rendezvous with each — `ermes_test_shared/lib/src/nat_mesh_*`.
2. Star: one hub local, N spokes as a runner matrix (`strategy.matrix.spoke`).
3. Mesh-3peer: three jobs (or 2 local + 1 runner), full pairwise rendezvous.
4. Group-churn: two stable peers on runners, churn node local (leave/rejoin).
5. Gate on `encrypted` first — Azure↔Azure runner↔runner punches are the hardest
   pairing and may require TURN before mesh can pass.

| Scenario | id | Actions | PC | Notes |
|---|---|---|---|---|
| star-topology | `star-topology` | 📝 | 📝 | hub holds N connections; `getConnections()` settles to N |
| mesh-3peer | `mesh-3peer` | 📝 | 📝 | three pairwise connections, no cross-talk |
| group-churn | `group-churn` | 📝 | 📝 | one peer leaves/rejoins, others unaffected |

## Excluded from CI (two-PC only)
`dual-net-change`, `rekey-on-reconnect`, `relay-failover`, `nat-type-matrix` —
need a real NAT-mapping change or control of the runner's NAT type.

---
**Progress**: P2 ✅ · P4 ✅ · P5 ✅ · P6 📝 (todo-only) · P1/P3 already done.
