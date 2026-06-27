# TODO — flap (sub-threshold)

**Scenario**: `NAT_SCENARIO=flap`
**CI fit**: ✅ short break produced on the LOCAL peer's data path
**Status**: [ ] not started

## Goal
Drop the link for less than `linkSilenceThreshold` (8 s) and restore it. The
connection must NOT be torn down — the silence detector must not over-react.

## Core path
- `linkSilenceThreshold` in `NatTestProtocol`.
- Silence detection in the heartbeat engines (must not trip a reconnect).

## Actions wiring
- `side=b-only` (responder on the runner), initiator local.
- Produce the break **locally**: drop outbound UDP to the peer for 3–5 s (local
  firewall rule) while keeping the relay/STUN reachable, then restore. The
  runner needs no manipulation.
- `NAT_SCENARIO=flap` on both binaries.

## Asserts (strict)
- No reconnect / re-rendezvous triggered (no `handlePeerDisconnect`).
- At most a couple of missed beats, then the exchange catches up.
- No duplicate connection created.

## Metric line
`flap missedBeats=<n> reconnectTriggered=false`
