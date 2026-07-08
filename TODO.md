# NAT reconnection scenarios — failure triage & fix plan

Run: `melos run test:github:all:onebyone` (peer-a local + peer-b on GitHub Actions).

## Summary of last full run

| Scenario            | peer-a | peer-b | Root cause |
|---------------------|--------|--------|------------|
| encrypted           | PASS   | PASS   | —          |
| rekey               | PASS   | PASS   | —          |
| flap                | PASS   | PASS   | —          |
| lossless-reconnect  | PASS   | PASS   | —          |
| fragmented-break    | PASS   | PASS   | —          |
| gap-detection       | PASS   | PASS   | —          |
| throughput          | PASS   | PASS   | —          |
| large-payload       | PASS   | PASS   | —          |
| keepalive           | PASS   | PASS   | —          |
| lossy               | PASS   | PASS   | —          |
| latency-jitter      | PASS   | PASS   | —          |
| mtu-edge            | PASS   | PASS   | —          |
| **graceful-reconnect** | PASS | **FAIL** | Bug A |
| **flap-storm**      | **FAIL** | **FAIL** | Bug A (peer-b) + cascade (peer-a) |
| **peer-restart**    | **FAIL** | **FAIL** | Bug B |
| **long-outage**     | **FAIL** | **FAIL** | Bug B |

---

## Bug A — survivor demands 3 post-reconnect heartbeats but only sees 2

**Symptom (peer-b):**
`Bad state: Only 2 heartbeat(s) after reconnect within 300s; need 3`
at `nat_reconnect_responder.dart:218`.

**Root cause:**
After re-rendezvous the initiator (`ReconnectBreaks._reRendezvousAndResume`) pumps
until it collects `postReconnectHeartbeats` (3) fresh **acks**, then returns and
immediately sends `endOfTests`. The survivor captures its `baseline` one beat
behind the initiator (the beat in flight during round-trip confirmation is
counted pre-baseline), so requiring the full 3 fresh beats on the survivor side
deadlocks — the initiator is already satisfied and gone.

`flap-storm` peer-b fails the same way; peer-a then times out on the *next* flap
cycle because the survivor already exited (cascade, not an independent bug).

**Fix (DONE, in working tree — needs commit + push):**
`nat_reconnect_responder.dart` `_reconnectAndResume`: require just **one** fresh
beat (`while (_received <= baseline)`) instead of the full count. The initiator
side still gates on the full `postReconnectHeartbeats`, so resumption is proven.

- [x] Code change written
- [ ] Commit + push to `develop` (runner uses the pushed code, not local tree)
- [ ] Re-run `graceful-reconnect` and `flap-storm`

---

## Bug B — signal goes stale after the initiator's NAT port changes

**Symptom:**
- peer-a/peer-b: `punched but no round-trip (packets did not cross)` for every
  attempt, then `NatRendezvousException` / `TimeoutException`.
- The starving side logs `DIALED PEER SIGNAL ... age=` growing monotonically
  (16s → 61s → 121s → 181s → …).
- long-outage: `CoreException: Timeout waiting for peer signal after 60 attempts`
  once the age crosses `2 × secondsIntervalOpening` (120s).

**Root cause:**
`peer-restart` (hard-kill + relaunch → new UDP socket → new external port) and
`long-outage` (mapping recycled during the >10 min break) both change the
initiator's external NAT port. The rendezvous loop re-punches each window by
calling `orc.openConnection(peer)` and its doc comment states *"Each attempt
re-publishes a fresh signal"*. But `OrcErmes.openConnection` short-circuits:

```dart
final existing = _peers[peer];
if (existing != null && existing.isConnected()) {
  return;   // <-- no createSignal / setSignal: owner signal never refreshed
}
```

The first punch leaves an ErmesPeer that reports `isConnected()` optimistically
(SHSP link "up") even though round-trip pings don't cross (the counterpart is
dialing the now-dead old port). From then on every `openConnection` returns
early, so the initiator stops republishing. Its relay signal ages out, the
counterpart's `_isStale` (`orc_ermes_connection_opener.dart:226`) rejects it, and
neither side ever learns the other's live endpoint.

**Fix (DONE, in working tree):**
`OrcErmes.openConnection` now republishes the owner signal on the
already-connected short-circuit path, restoring the "every attempt republishes"
contract the rendezvous relies on, without tearing down the warm connection.

- [x] Code change written (`orc_ermes.dart` + `orc_ermes_connection_opener.dart`)
- [x] `dart analyze` clean; no regression vs baseline (the only aggregated-suite
      failures are the pre-existing flaky relay-dependent `getLastSignal*` tests,
      which fail non-deterministically with and without this change)
- [ ] Re-run `peer-restart` and `long-outage` on Actions

### Follow-up / deeper hardening (not blocking)
- `ErmesPeer.isConnected()` is a **false positive** when the SHSP link is up but
  packets don't actually cross. A liveness-gated `isConnected()` would let the
  short-circuit itself detect the dead mapping and re-dial. Larger change; track
  separately.

---

## Verification checklist
- [ ] `melos run test` (local suite) still green
- [ ] `melos run test:github:all:onebyone` → all 16 scenarios PASS
- [ ] Confirm peer-b verdicts on Actions per workflow:
  - `gh run list --workflow=nat-graceful-reconnect.yml`
  - `gh run list --workflow=nat-peer-restart.yml`
  - `gh run list --workflow=nat-flap-storm.yml`
  - `gh run list --workflow=nat-long-outage.yml`
