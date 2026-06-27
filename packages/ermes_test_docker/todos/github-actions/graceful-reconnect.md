# TODO — graceful-reconnect

**Scenario**: `NAT_SCENARIO=graceful-reconnect`
**CI fit**: ✅ teardown initiated by the LOCAL peer; runner is the responder
**Status**: [ ] not started

## Goal
The local peer disconnects on purpose (clean teardown via `disconnectNow`),
then both sides re-rendezvous and resume the heartbeat with no message loss.

## Core path
- `disconnectNow` message (defined in `DockerMsgType`, currently unused).
- `OrcErmes.destroy` / `clearConnection` on the runner side.
- `openConnection()` re-rendezvous on resume.

## Actions wiring
- `side=b-only` (responder on the runner), initiator local.
- The local initiator sends `disconnectNow`, tears its SHSP connection down,
  pauses, then re-rendezvous — no clock control needed on the runner.
- `NAT_SCENARIO=graceful-reconnect` selects this path on both binaries.

## Asserts (strict)
- Teardown raises no error and leaves no dangling connection in
  `getConnections()` on the runner.
- Reconnect completes within `reconnectBudget`.
- `postReconnectHeartbeats` acked after resume; zero loss after resume.

## Metric line
`graceful-reconnect reconnectTimeMs=<n> messagesLost=<x>/<total>`
