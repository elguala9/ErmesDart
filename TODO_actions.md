# TODO — NAT GitHub Actions failures

## Problem

Some `.github/workflows/nat-*.yml` scenarios fail. They are **not** the unit test
suite — each runs a real Ermes peer pair (peer-a local + peer-b on a GitHub runner,
via `scripts/run-test-github-*.sh`) that finds the other through public Nostr
relays + STUN and attempts a direct UDP hole-punch.

All failures share the exact same error, on BOTH sides:

```
NatRendezvousException: failed to connect ... after N attempt(s);
last error: punched but no round-trip (packets did not cross)
```

| Scenario | Run 2026-07-06 |
|---|---|
| encrypted, rekey, graceful-reconnect, lossless-reconnect, fragmented-break, gap-detection, throughput, large-payload, keepalive, lossy, latency-jitter, mtu-edge, flap-storm | pass |
| **peer-restart, flap, long-outage** | **fail — flaky** (flap-storm failed on earlier runs and passed today) |

## Root cause — REVISED 2026-07-06 (the previous "symmetric NAT" diagnosis was wrong)

The earlier diagnosis ("Azure symmetric, port-randomizing SNAT") is **contradicted
by the evidence**:

1. All three failing peer-b runners printed
   `[NAT-DIAG] ... MAPPING=endpoint-independent PORT-OVER-TIME=stable VERDICT=cone
   — hole-punch CAN work, so a re-punch failure is OUR bug`.
2. The "external port rotating on each attempt" DIAG lines are an **artifact**:
   `probeExternalAddress()` (`nat_diag.dart:47`) binds a **throwaway socket per
   call**, so every probe necessarily shows a new (sequential on Azure) port. The
   SHSP socket actually advertised in the signal keeps the SAME port across all
   attempts of a run.
3. `flap` and `long-outage` failed at the **initial rendezvous, before any break**
   — the same punch that passed in 13/16 scenarios minutes earlier.
4. The run already used the "local peer-a (cone) + runner peer-b" topology — the
   old mitigation #2 — with cone NAT verified on both sides, and still failed.

**Working hypothesis (strong, not yet log-confirmed): stale peer signal.**
Both sides flood pings for 90 s in epoch-synchronized windows, both behind cone
NATs, yet packets never cross → at least one side is punching a **dead endpoint**
taken from a stale signal. The mechanism:

- Signals carry a **600 s TTL** (`ermes_signaling_handler.dart:105`) and the two
  Nostr identities are **fixed across all 16 back-to-back scenarios**, so relays
  still serve valid signals of the previous scenario's dead process. All three
  failed scenarios started **within 1–2 min** of the previous one; passing ones
  raced the same window and won → flakiness.
- `retrieveLast` (nostr_signaling) uses `limit:1` per relay across 4 relays: the
  first relay to answer may not have the fresh publish yet.
- `_waitForPeerSignal` (`orc_ermes_connection_opener.dart:166`) accepts the first
  **non-expired** signal — up to 10 minutes old — with no freshness bound.
- The fresher-signal redial watch lasts only **5 s** (`_redialConfirmMs`,
  `orc_ermes_connection_opener.dart:41`) while the confirm flood lasts 90 s: a
  fresh republish arriving at second 6 is ignored for the rest of the attempt.
- `peer-restart` fails most consistently because it creates the stale signal **by
  design**: the killed peer-a instance leaves a valid signal with a dead port.
- `_isSelfSignal` (commit cb19c84) only compares against the CURRENT own
  endpoint, so an own stale signal with a different port slips past.
- Diagnostic gap: the peer signal actually **dialed** is never logged — the logs
  only ever show the peer's own signal echoed by the relay.

## Actions (in order — TURN is explicitly ruled out)

- [x] **1. Confirm**: log the peer signal actually dialed. `logDialedPeerSignal`
      added in `nat_verbose.dart`, called from the rendezvous loop right after
      each punch (`nat_rendezvous.dart`). A `DIALED PEER SIGNAL: ...` line now
      shows the endpoint + timestamp we punched toward, discriminating a stale
      dial from a live-but-filtered punch on the next run.
- [x] **2. Fresh identities per scenario** (test harness only): new
      `bin/nat_gen_keys.dart` prints a fresh alice+bob keypair per dispatch;
      `lib/github-nat-driver.sh` generates them (unless
      `ERMES_NAT_FIXED_IDENTITIES=1`) and passes them to the runner via new
      `alice_pubkey` / `bob_pubkey` / `bob_privkey` workflow inputs (all 18
      `nat-*.yml` patched). Cross-run stale signals can no longer match.
- [x] **3. Freshness bound on accepted signals**: `OrcConnectionOpener._isStale`
      rejects a peer signal older than `_maxSignalAgeFactor` (2) declared
      republish periods, in both `_waitForPeerSignal` and
      `_awaitConnectionOrFresher`. Signals that declare no period keep the
      expiry-only behaviour. Regression test `testOrcErmesStaleSignal`.
      Required a wire-format bump: `SignalErmes` now serialises
      `secondsIntervalOpening` as a 9th field (8-field signals still parse).
- [~] **4. Extend the fresher-signal watch** — NOT done on purpose. The watch
      runs its FULL budget whenever the dialed peer does not flip
      `isConnected()` (e.g. right after a reconnect), so lengthening it stalls
      every such open (proven: the full-flow reconnect test timed out at 30 s).
      Re-attempts against a stale port are already the OUTER rendezvous loop's
      job, and action 3 removes the stale target up front, so `_redialConfirmMs`
      stays at 5 s.
- [x] **5. Prefer the newest signal**: `ErmesSignalingServer.getSignal` and the
      subscription push handler now never let the cache regress — they keep the
      signal with the newest `epochTimestampStartConversation` across the relay
      fetch and any pushed event (mitigates `retrieveLast`'s first-relay race).
- [x] (optional) `probeExternalAddress` now reuses one long-lived socket, so the
      DIAG "CHANGED" line reflects real NAT mapping churn instead of a fresh
      socket each call.

Rejected: `continue-on-error` on the failing scenarios (hides the bug); TURN
relay (excluded by decision).

## Status 2026-07-06

Code + harness changes implemented and green locally: `dart analyze` clean on
ermes_core / ermes_signaling / ermes_test_shared / ermes_test; centralized suite
`concrete_implementations_test.dart` passes (611), signaling package tests pass.
Next: push the branch and re-run `melos run test:github:all:onebyone` — the new
`DIALED PEER SIGNAL` line will confirm the stale-dial hypothesis on any residual
failure, and fresh identities should stop the cross-run contamination.

## References

- Failing runs (2026-07-06): peer-restart 28775684809, flap 28776038107,
  long-outage 28776608427 — peer-b NAT-DIAG says cone in all three.
- `packages/ermes_core/lib/src/orc_ermes_connection_opener.dart` — signal
  fetch/dial/redial (`_waitForPeerSignal`, `_awaitConnectionOrFresher`,
  `_isSelfSignal`, `_redialConfirmMs`).
- `packages/ermes_signaling/lib/src/ermes_signaling_handler.dart:105` — 600 s TTL.
- `packages/ermes_signaling/lib/src/ermes_signaling_server.dart:108` — `getSignal`
  + cache gate (`forceRefresh`).
- `packages/ermes_test_shared/lib/src/nat_rendezvous.dart` — rendezvous loop and
  90 s confirm flood.
- `packages/ermes_test_shared/lib/src/nat_diag.dart:47` — throwaway-socket probe
  (source of the misleading "port rotating" evidence).
- `NAT_ACTIONS_FAILURE_REPORT.md` — original (superseded) diagnosis.
