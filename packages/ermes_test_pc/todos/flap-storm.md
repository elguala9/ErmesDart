# TODO — flap-storm

**Scenario**: `NAT_SCENARIO=flap-storm`
**Status**: [ ] not started

## Goal
Break and restore the link N times in a row (configurable). Verifies each cycle
reconnects and that nothing leaks across cycles — the long-term robustness of
the reconnect path.

## Core path
- Repeated `handlePeerDisconnect()` → backoff → `openConnection()`.
- Backoff must reset correctly between cycles; no listener/connection buildup.

## Setup
Two PCs (or the container driver looped). `FLAP_CYCLES` env controls N; each
break is > `linkSilenceThreshold` so it genuinely reconnects.

## Steps
1. Establish the steady heartbeat.
2. For N cycles: break > threshold, restore, wait for resume.
3. Verify the final state is healthy.

## Asserts (strict)
- Every cycle reconnects within `reconnectBudget`.
- `getConnections()` count stays at exactly one peer (no duplicates).
- No unbounded memory / listener growth across cycles.
- Backoff resets after each successful reconnect.

## Metric line
`flap-storm cycles=<N> reconnectsOk=<N> maxReconnectMs=<n> leakedConnections=<n>`
