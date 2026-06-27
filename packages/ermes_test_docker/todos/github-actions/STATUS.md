# GitHub Actions tests — master status

Single tracking sheet for the CI-runnable scenarios. Update the **Status** and
**Result** columns as each one is wired and run. Per-scenario specs live in the
sibling files; see [README.md](README.md) for the shared harness and wiring.

Legend — **Status**: ⬜ not started · 🟡 in progress · ✅ done.
**Result**: — not run · 🟢 PASS · 🔴 FAIL · ⏭️ blocked (needs TURN / NAT).

## Prerequisite (do first)
- ✅ Extend `nat-test.yml` with a `scenario` input + `NAT_SCENARIO` env step.
- ✅ Extend the env-driven dispatch in `nat_peer_a.dart` / `nat_peer_b.dart`
      (`isEncryptedScenario()` / `isRekeyScenario()` alongside `network-change`).
- ⬜ Run **encrypted** as the local↔Azure traversal smoke test — gates everything.

## P3 — Encryption / key exchange (pure exchange)
| Scenario | Spec | Status | Result | Notes |
|---|---|---|---|---|
| encrypted | [encrypted.md](encrypted.md) | ✅ | — | implemented; run first (smoke). `sh scripts/run-test-github-encrypted.sh` |
| rekey | [rekey.md](rekey.md) | ✅ | — | implemented. `sh scripts/run-test-github-rekey.sh` |

## P1 — Disconnection / reconnection (break on the LOCAL peer)
| Scenario | Spec | Status | Result | Notes |
|---|---|---|---|---|
| graceful-reconnect | [graceful-reconnect.md](graceful-reconnect.md) | ✅ | — | implemented. `sh scripts/run-test-github-graceful-reconnect.sh` |
| peer-restart | [peer-restart.md](peer-restart.md) | ✅ | — | implemented (driver kills+relaunches local). `sh scripts/run-test-github-peer-restart.sh` |
| flap | [flap.md](flap.md) | ✅ | — | implemented. `sh scripts/run-test-github-flap.sh` |
| flap-storm | [flap-storm.md](flap-storm.md) | ✅ | — | implemented; `FLAP_CYCLES` overridable. `sh scripts/run-test-github-flap-storm.sh` |
| long-outage | [long-outage.md](long-outage.md) | ✅ | — | implemented; >10 min, `timeout_minutes=30`. `sh scripts/run-test-github-long-outage.sh` |

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
**Progress**: 0 / 17 scenarios passing · prerequisite 2 / 3 done ·
P3 (encrypted, rekey) implemented, awaiting a CI run ·
P1 (graceful-reconnect, peer-restart, flap, flap-storm, long-outage) implemented,
awaiting a CI run.

**P1 note**: the break is produced IN-PROCESS on the local peer (the engine
closes/pauses its own link) rather than via OS firewall rules, so the driver
scripts stay portable across Linux and Windows (Git Bash) and need no root.
`peer-restart` is the one exception — its driver hard-kills and relaunches the
local process. Each scenario prints its spec metric line on one greppable line.
