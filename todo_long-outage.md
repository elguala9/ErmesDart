# TODO: NAT `long-outage` scenario fails on re-punch after the break

## Status

Reproduced twice with matched local (`peer-a`) and Actions (`peer-b`) logs from
the same dispatch (run id `28953532005`, branch `develop`,
`melos run test:github:all:onebyone` / `scripts/run-test-github-long-outage.sh`).
Both sides ran correctly in lockstep — this is a real bug in the reconnect
path, not a test-running mistake.

Local log: `$TMPDIR/ermes-github-tests/long-outage.log`
Actions run: `gh run view 28953532005` (job `peer-b (responder)`, conclusion
`failure`)

## Symptom

1. Initial connection succeeds (`STEADY EXCHANGE LIVE`).
2. `longOutage()` closes the connection and sleeps for the outage duration
   (~660s).
3. Both sides come back and try to re-rendezvous. Every attempt reaches
   `"punched but no round-trip (packets did not cross)"` against the peer's
   **pre-break** address — the two sides never manage to punch to each
   other's current address again.
4. After ~10 attempts / ~21 minutes both sides exhaust their budget and fail:
   - peer-a: `RESULT: FAIL -> TimeoutException after 0:21:30.000000`
   - peer-b: `RESULT: FAIL -> NatRendezvousException: ... after 11 attempt(s)`
5. The startup diagnostic already calls this out:
   `VERDICT=cone — hole-punch CAN work, so a re-punch failure is OUR bug`.

## Confirmed bug #1 — `keepWarm()` can be a silent no-op

- `_RendezvousLiveness.keepWarm()` / `_send()` in
  `packages/ermes_test_shared/lib/src/nat_rendezvous.dart:322-337` calls
  `_orc.send(...)` and swallows **any** exception.
- `OrcErmes.send()` in `packages/ermes_core/lib/src/orc_ermes.dart:121-133`
  throws `CoreException('Peer $peer is not connected. Call openConnection
  first.')` immediately, **before touching the socket**, whenever there is no
  `ErmesPeer` registered for that peer yet.
- There is no registered peer during:
  - the raw outage sleep in `longOutage()`
    (`packages/ermes_test_shared/lib/src/nat_reconnect_breaks.dart:124-125`,
    right after `closeConnection`, before the first re-rendezvous attempt) —
    keepWarm is not even called here, so the socket is 100% idle for up to
    660s;
  - the gap after any `openConnection` attempt that throws (peer-signal
    timeout, relay hiccup, etc.) instead of "punched but no round-trip".
- Evidence this actually bites: in the peer-a log, attempt 10 throws
  (`CoreException: Timeout waiting for peer signal after 60 attempts`), then
  the next `keepWarm` gap (57s) passes, and attempt 11's diagnostic reports
  `ourExternal=93.57.251.202:11353 (CHANGED from 93.57.251.202:11699)` — the
  local NAT mapping drifted precisely in the one window where no keep-alive
  traffic could have gone out.
- Net effect: the "hold the mapping warm across the outage" mechanism the
  code comments describe is defeated exactly when it's needed most.

## Open question — why does the fresh republished signal never reach the peer?

- `OrcConnectionOpener.open()` calls `publishOwnSignal(peer)` — and therefore
  a fresh `signalingHandler.createSignal(...)` — on **every** `openConnection`
  call (`packages/ermes_core/lib/src/orc_ermes_connection_opener.dart:61-66`).
- `createSignal()` re-probes the public address every time via
  `discoverPublicAddress(...)`
  (`packages/ermes_signaling/lib/src/ermes_signaling_handler.dart:79-107`,
  `packages/ermes_signaling/lib/src/stun/stun_discovery.dart:14-41`).
- So in theory each side re-publishes its *current* address on every
  rendezvous attempt.
- But in the logs, peer-b's `DIALED PEER SIGNAL` for peer-a stays pinned at
  the exact same `93.57.251.202:12191` for **all 11 post-break attempts**,
  even though peer-a's own independent diagnostic probe shows its real
  external port has moved to `11699` and later `11353`. Peer-b never sees an
  updated peer-a signal at all.
- This means somewhere between "peer-a publishes a fresh signal every
  attempt" and "peer-b reads a fresh signal every attempt" the updated
  address is getting lost. Candidates, not yet checked:
  - `packages/ermes_signaling/lib/src/stun/fresh_socket_stun.dart` — does the
    fresh-socket STUN probe actually return a new external port every call,
    or does it reuse a cached/bound socket whose result was memoized at
    first use?
  - the Nostr relay `setSignal`/`getSignal` path — does `forceRefresh: true`
    actually bypass every cache layer, and do the relays used
    (`nos.lol`, `relay.damus.io`, ...) rate-limit/dedupe rapid replaceable
    events from the same pubkey, silently dropping the republish?
  - `_isStale` / `_isSelfSignal` filtering in
    `packages/ermes_core/lib/src/orc_ermes_connection_opener.dart` — could a
    legitimately fresh signal be getting rejected as "stale" by mistake?

## Next steps

1. **Instrument first, before changing behavior.** Add a print of the
   ipv4/port that `publishOwnSignal` actually sends to `setSignal` on
   *every* attempt (not just the one `logOwnSignal` prints on success), on
   both peer-a and peer-b. Re-run `long-outage` (or the cheaper smoke path:
   `LONG_OUTAGE_SECONDS=120 TIMEOUT_MINUTES=10
   ./scripts/run-test-github-long-outage.sh`) and compare:
   - what peer-a *sends* to the relay after the break, vs.
   - what peer-b *reads back* for peer-a on each attempt.
   This tells us definitively whether the break is on the publish side
   (stale STUN result) or the read side (relay/cache not returning the
   fresh event).
2. Read `fresh_socket_stun.dart` to confirm whether it reuses a long-lived
   probe socket/cached result across calls.
3. Fix `_RendezvousLiveness.keepWarm`/`_send` so a missing `ErmesPeer` entry
   does not silently prevent any keep-alive traffic — either send a raw
   keepalive directly on the shared socket, or keep an optimistic peer
   entry registered across re-dial attempts so `IOrcErmes.send` never
   throws mid-rendezvous.
4. Once the propagation gap from step 1 is identified, fix it at its actual
   layer (STUN caching, relay publish/read, or stale-signal filtering) —
   do not paper over it by only patching `keepWarm`.
5. Re-run the full scenario (`melos run test:github:long-outage` or
   `test:github:all:onebyone -- long-outage`) and confirm:
   - `reconnectTimeMs` is reported and within budget,
   - no `(CHANGED ...)` port drift appears right after a failed attempt,
   - both `peer-a (local): PASS` and `peer-b (runner): PASS`.
