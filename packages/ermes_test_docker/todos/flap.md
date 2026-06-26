# TODO — flap (sub-threshold)

**Scenario**: `NAT_SCENARIO=flap`
**Status**: [ ] not started

## Goal
Drop the link for less than `linkSilenceThreshold` (8 s) and restore it. The
connection must NOT be torn down — verifies the silence detector does not
over-react to a single brief blip.

## Core path
- `linkSilenceThreshold` in `NatTestProtocol`.
- Silence detection in the heartbeat engines (must not trip a reconnect).

## Setup
Two PCs. The break is short (e.g. 3–5 s), well under the 8 s threshold.

## Steps
1. Establish the steady heartbeat.
2. Drop the link for < `linkSilenceThreshold`, then restore.
3. Heartbeat continues without a full reconnect.

## Asserts (strict)
- No reconnect / re-rendezvous is triggered (no `handlePeerDisconnect`).
- At most a couple of missed beats, then the exchange catches up.
- No duplicate connection created.

## Metric line
`flap missedBeats=<n> reconnectTriggered=false`
