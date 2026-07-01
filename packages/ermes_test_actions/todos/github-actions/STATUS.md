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
| signal-cipher | [signal-cipher.md](signal-cipher.md) | ✅ | — | implemented (`NatSignalCipherExchange`); ECDH key in the signal, no in-band handshake. `sh scripts/run-test-github-signal-cipher.sh` |

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
| lossless-reconnect | [lossless-reconnect.md](lossless-reconnect.md) | ✅ | — | implemented. `sh scripts/run-test-github-lossless-reconnect.sh` |
| fragmented-break | [fragmented-break.md](fragmented-break.md) | ✅ | — | implemented; `FRAGMENT_BYTES` overridable. `sh scripts/run-test-github-fragmented-break.sh` |
| gap-detection | [gap-detection.md](gap-detection.md) | ✅ | — | implemented (`requestMissing` path). `sh scripts/run-test-github-gap-detection.sh` |

## P4 — Load / stress (pure exchange)
| Scenario | Spec | Status | Result | Notes |
|---|---|---|---|---|
| throughput | [throughput.md](throughput.md) | ✅ | — | implemented; `TARGET_RATE`/`DURATION`. runner egress caps the rate. `sh scripts/run-test-github-throughput.sh` |
| large-payload | [large-payload.md](large-payload.md) | ✅ | — | implemented; `SIZES`. `sh scripts/run-test-github-large-payload.sh` |
| keepalive | [keepalive.md](keepalive.md) | ✅ | — | implemented; `IDLE_DURATION` (keep inside job timeout). `sh scripts/run-test-github-keepalive.sh` |

## P5 — Adverse conditions (netem ON the Linux runner)
| Scenario | Spec | Status | Result | Notes |
|---|---|---|---|---|
| lossy | [lossy.md](lossy.md) | ✅ | — | implemented; workflow `tc netem loss ${LOSS_PCT}%` on peer-b. `sh scripts/run-test-github-lossy.sh` |
| latency-jitter | [latency-jitter.md](latency-jitter.md) | ✅ | — | implemented; workflow `tc netem delay ${DELAY_MS}/${JITTER_MS}`. `sh scripts/run-test-github-latency-jitter.sh` |
| mtu-edge | [mtu-edge.md](mtu-edge.md) | ✅ | — | implemented; workflow `ip link set mtu ${MTU}`. `sh scripts/run-test-github-mtu-edge.sh` |

## P6 — Multi-peer (one job per peer) — 📝 TODO ONLY
Needs new rendezvous-capable 3-peer binaries (the existing `ermes_test_docker`
alice/bob/charlie bins use a fixed Docker network, not the public-NAT
rendezvous). Implementation plan in
`packages/ermes_test_shared/TODO_REMAINING_SCENARIOS.md`.

| Scenario | Spec | Status | Result | Notes |
|---|---|---|---|---|
| star-topology | [star-topology.md](star-topology.md) | 📝 | — | matrix of spokes |
| mesh-3peer | [mesh-3peer.md](mesh-3peer.md) | 📝 | — | runner↔runner + local↔Azure |
| group-churn | [group-churn.md](group-churn.md) | 📝 | — | churn the local peer |

## Excluded from CI (two-PC only — see `../`)
`dual-net-change`, `rekey-on-reconnect`, `relay-failover`, `nat-type-matrix` —
need a real NAT-mapping change or control of the runner's NAT type.

---
**Progress**: 15 / 18 scenarios implemented (awaiting CI runs) · P6 (3) todo-only ·
prerequisite 2 / 3 done · P3 (encrypted, rekey, signal-cipher) · P1 (graceful-reconnect,
peer-restart, flap, flap-storm, long-outage) · P2 (lossless-reconnect,
fragmented-break, gap-detection) · P4 (throughput, large-payload, keepalive) ·
P5 (lossy, latency-jitter, mtu-edge).

**P1/P2 note**: the break is produced IN-PROCESS on the local peer (the engine
closes/pauses its own link) rather than via OS firewall rules, so the driver
scripts stay portable across Linux and Windows (Git Bash) and need no root.
`peer-restart` is the one exception — its driver hard-kills and relaunches the
local process. Each scenario prints its spec metric line on one greppable line.

**P5 note**: the path degradation (packet loss / latency+jitter / small MTU) is
applied by the workflow to the runner peer-b (Linux + root: `tc netem` /
`ip link set mtu`) and torn down in an `if: always()` step. The Dart engine is
the same reliable exchange as P4 — it just must still complete under the
degradation. The netem values are workflow env (`LOSS_PCT`, `DELAY_MS`,
`JITTER_MS`, `MTU`).
