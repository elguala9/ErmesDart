# TODO — long-outage

**Scenario**: `NAT_SCENARIO=long-outage`
**Status**: [ ] not started

## Goal
Break the link for longer than the relay signal lifetime
(`epochTimestampExpireConversation` = 10 min) so the published signal expires,
then restore. Verifies both peers republish a fresh signal and re-rendezvous —
no stale-signal dead-port punch.

## Core path
- Signal expiry on the relay.
- Both peers republish a fresh STUN signal on resume.
- `OrcConnectionOpener.open()` re-dial toward the live mapping.

## Setup
Two PCs. The break must last > 10 min, so this is a long-running manual run
(or a CI job with an extended timeout).

## Steps
1. Establish the steady heartbeat.
2. Cut the moving peer's link for > 10 minutes (signal expires).
3. Restore the link.
4. Both republish and re-rendezvous; heartbeat resumes.

## Asserts (strict)
- Reconnect succeeds even though the old signal is gone.
- No punch toward the stale/dead port (no wasted dial cycle on expired signal).
- `postReconnectHeartbeats` acked after resume.

## Metric line
`long-outage outageMs=<n> reconnectTimeMs=<n> messagesLost=<x>/<total>`

## Note
This is the one scenario that deliberately exercises the 10-min expiry — do NOT
use fresh identities to dodge it.
