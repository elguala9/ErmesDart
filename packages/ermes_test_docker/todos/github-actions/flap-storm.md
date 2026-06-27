# TODO — flap-storm

**Scenario**: `NAT_SCENARIO=flap-storm`
**CI fit**: ✅ N break/restore cycles produced on the LOCAL peer
**Status**: [ ] not started

## Goal
Break and restore the link N times in a row. Each cycle must reconnect and
nothing must leak across cycles (long-term robustness of the reconnect path).

## Core path
- Repeated `handlePeerDisconnect()` → backoff → `openConnection()`.
- Backoff must reset correctly; no listener/connection buildup.

## Actions wiring
- `side=b-only` (responder on the runner), initiator local.
- A local loop produces `FLAP_CYCLES` breaks (each > `linkSilenceThreshold` so
  it genuinely reconnects) by toggling outbound UDP to the peer.
- `NAT_SCENARIO=flap-storm`; `FLAP_CYCLES` env controls N.

## Asserts (strict)
- Every cycle reconnects within `reconnectBudget`.
- `getConnections()` count stays at exactly one peer (no duplicates).
- No unbounded memory / listener growth across cycles.
- Backoff resets after each successful reconnect.

## Metric line
`flap-storm cycles=<N> reconnectsOk=<N> maxReconnectMs=<n> leakedConnections=<n>`

## Runner caveats
- Size `FLAP_CYCLES` so total wall time stays under the job `timeout-minutes`.
