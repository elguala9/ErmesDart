# NAT GitHub Actions — Failure Diagnosis Report

## Context
The `.github/workflows/nat-*.yml` workflows are **not** the unit test suite (`dart test`).
Each one runs **two Ermes peers on two GitHub-hosted runners (Azure)** that find each
other through public Nostr relays + public STUN and attempt a **direct UDP hole-punch**
peer-to-peer. They exercise real NAT traversal, not application logic in isolation.

## What fails (run of 2026-07-05)
| Scenario | 2026-07-05 | 2026-07-03 |
|---|---|---|
| encrypted (ECDH+AES) | ✅ success | ✅ |
| rekey (rotate key) | ✅ success | ✅ |
| graceful-reconnect | ✅ success | ✅ |
| lossless-reconnect | ✅ success | ✅ |
| **flap** | ❌ **failure** | ✅ success |
| **flap-storm** | ❌ **failure** | ✅ success |
| **peer-restart** | ❌ **failure** | ❌ failure |
| **long-outage** | ❌ **failure** | ❌ failure |

## Root cause (confirmed from the logs)
All four failures share the **exact same error**:
```
NatRendezvousException: failed to connect ... after N attempt(s);
last error: punched but no round-trip (packets did not cross)
```
Sequence observed in every failed run (peer-b):
1. **The Nostr relay works** — the peer signal is read correctly (`<~ SIGNAL pushed by relay ...`).
2. **The punch is performed** — `Punched to ... on attempt N`.
3. **The round-trip is NOT confirmed** — ping/pong never cross (`confirmRoundTrip` fails)
   → tear-down → re-punch → fails again → the 6-minute budget
   (`NatTestProtocol.rendezvousBudget`) is exhausted.

Decisive evidence in **long-outage**: the *first* rendezvous succeeds
(`Round-trip confirmed (29s)`), then after the outage **every re-punch fails**.
This is the classic **symmetric NAT** signature: on the second punch the Azure NAT
assigns a **new external port**, different from the one advertised in the signal, so
packets are sent to a stale port and never cross.

## Conclusion
- **This is NOT a code regression** from the recent commits ("action rotate key",
  "fix bug actions", etc.). The scenarios those commits touch — encrypted, rekey,
  signal-cipher — **all pass**.
- It is an **infrastructure limitation**: UDP hole-punching between **two GitHub-hosted
  runners behind Azure SNAT (symmetric, port-randomizing)** is inherently unreliable,
  **especially on the cold re-punch** required by the reconnection scenarios
  (flap / flap-storm / peer-restart / long-outage).
- Scenarios that keep **a single warm mapping** (encrypted, rekey, graceful/lossless-reconnect)
  pass; those that require a **cold re-punch** fail, and do so **flakily**
  (flap/flap-storm passed on 2026-07-03).

## Relevant code / constants
- Timing: `packages/ermes_test_shared/lib/src/nat_test_protocol.dart`
  (`rendezvousBudget=6min`, `windowPeriodSeconds=60`, `windowOpenSeconds=10`,
  `rendezvousReconfirmWindow=90s`).
- Rendezvous logic: `packages/ermes_test_shared/lib/src/nat_rendezvous.dart`
  (`rendezvous()` + `_RendezvousLiveness.confirmRoundTrip`).

## Possible mitigations (none applied — diagnosis only)
1. **Resilient CI** — automatic workflow retry and/or mark the 4 reconnection scenarios
   as non-blocking (`continue-on-error`), keeping only the single-mapping scenarios blocking.
2. **Local peer + runner** — run the 4 scenarios with `side=b-only` on the runner and
   peer-a locally (already supported by `scripts/run-test-github-*.sh`), where the local
   NAT is cone-type and the punch succeeds.
3. **TURN relay fallback** — route traffic via TURN when the direct hole-punch does not
   cross (a real transport-level fix for symmetric NAT; requires a TURN server).

## How to reproduce the diagnosis
```
gh run list --limit 25
gh run view <run-id> --log-failed
```
The failed runs all show the `punched but no round-trip (packets did not cross)` signature.
