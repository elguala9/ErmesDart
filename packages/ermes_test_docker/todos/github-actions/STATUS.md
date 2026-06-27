# GitHub Actions tests — master status

Single tracking sheet for the CI-runnable scenarios. Update the **Status** and
**Result** columns as each one is wired and run. Per-scenario specs live in the
sibling files; see [README.md](README.md) for the shared harness and wiring.

Legend — **Status**: ⬜ not started · 🟡 in progress · ✅ done.
**Result**: — not run · 🟢 PASS · 🔴 FAIL · ⏭️ blocked (needs TURN / NAT).

## Prerequisite (do first)
- ⬜ Extend `nat-test.yml` with a `scenario` input + `NAT_SCENARIO` env step.
- ⬜ Extend the env-driven dispatch in `nat_peer_a.dart` / `nat_peer_b.dart`
      (today only `network-change` is wired via `isNetworkChangeScenario()`).
- ⬜ Run **encrypted** as the local↔Azure traversal smoke test — gates everything.

## P3 — Encryption / key exchange (pure exchange)
| Scenario | Spec | Status | Result | Notes |
|---|---|---|---|---|
| encrypted | [encrypted.md](encrypted.md) | ⬜ | — | smoke test — run first |
| rekey | [rekey.md](rekey.md) | ⬜ | — | |

## P1 — Disconnection / reconnection (break on the LOCAL peer)
| Scenario | Spec | Status | Result | Notes |
|---|---|---|---|---|
| graceful-reconnect | [graceful-reconnect.md](graceful-reconnect.md) | ⬜ | — | |
| peer-restart | [peer-restart.md](peer-restart.md) | ⬜ | — | |
| flap | [flap.md](flap.md) | ⬜ | — | |
| flap-storm | [flap-storm.md](flap-storm.md) | ⬜ | — | |
| long-outage | [long-outage.md](long-outage.md) | ⬜ | — | >10 min, burns CI minutes |

## P2 — Message reliability under churn (break on the LOCAL peer)
| Scenario | Spec | Status | Result | Notes |
|---|---|---|---|---|
| lossless-reconnect | [lossless-reconnect.md](lossless-reconnect.md) | ⬜ | — | |
| fragmented-break | [fragmented-break.md](fragmented-break.md) | ⬜ | — | |
| gap-detection | [gap-detection.md](gap-detection.md) | ⬜ | — | |

## P4 — Load / stress (pure exchange)
| Scenario | Spec | Status | Result | Notes |
|---|---|---|---|---|
| throughput | [throughput.md](throughput.md) | ⬜ | — | runner egress caps the rate |
| large-payload | [large-payload.md](large-payload.md) | ⬜ | — | |
| keepalive | [keepalive.md](keepalive.md) | ⬜ | — | keep idle inside job timeout |

## P5 — Adverse conditions (netem ON the Linux runner)
| Scenario | Spec | Status | Result | Notes |
|---|---|---|---|---|
| lossy | [lossy.md](lossy.md) | ⬜ | — | `tc netem loss` |
| latency-jitter | [latency-jitter.md](latency-jitter.md) | ⬜ | — | `tc netem delay` |
| mtu-edge | [mtu-edge.md](mtu-edge.md) | ⬜ | — | `ip link set mtu` |

## P6 — Multi-peer (one job per peer)
| Scenario | Spec | Status | Result | Notes |
|---|---|---|---|---|
| star-topology | [star-topology.md](star-topology.md) | ⬜ | — | matrix of spokes |
| mesh-3peer | [mesh-3peer.md](mesh-3peer.md) | ⬜ | — | runner↔runner + local↔Azure |
| group-churn | [group-churn.md](group-churn.md) | ⬜ | — | churn the local peer |

## Excluded from CI (two-PC only — see `../`)
`dual-net-change`, `rekey-on-reconnect`, `relay-failover`, `nat-type-matrix` —
need a real NAT-mapping change or control of the runner's NAT type.

---
**Progress**: 0 / 17 scenarios passing · prerequisite 0 / 3 done.
