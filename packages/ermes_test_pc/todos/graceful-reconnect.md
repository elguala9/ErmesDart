# TODO — graceful-reconnect

**Scenario**: `NAT_SCENARIO=graceful-reconnect`
**Status**: [ ] not started

## Goal
A peer disconnects on purpose (clean teardown), then both sides re-rendezvous
and resume the exchange with no message loss. Exercises the orderly shutdown
path rather than a silence-detected break.

## Core path
- `disconnectNow` message (already defined in `DockerMsgType`, currently unused).
- `OrcErmes.destroy` / `clearConnection` on the receiving side.
- `openConnection()` re-rendezvous on resume.

## Setup
Two PCs, public relay + STUN. Reuse `NatHeartbeatInitiator/Responder`.

## Steps
1. Establish the steady heartbeat (`preBreakHeartbeats` acked).
2. Initiator sends `disconnectNow`; both sides tear the SHSP connection down
   cleanly (no exception, no error log).
3. After a short pause both re-rendezvous and resume the heartbeat.

## Asserts (strict)
- Teardown raises no error and leaves no dangling connection in
  `getConnections()`.
- Reconnect completes within `reconnectBudget`.
- `postReconnectHeartbeats` acked after resume; zero loss after resume.

## Metric line
`graceful-reconnect reconnectTimeMs=<n> messagesLost=<x>/<total>`
