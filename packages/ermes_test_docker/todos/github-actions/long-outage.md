# TODO — long-outage

**Scenario**: `NAT_SCENARIO=long-outage`
**CI fit**: ⚠️ feasible but long-running — burns CI minutes
**Status**: [ ] not started

## Goal
Break the link for longer than the relay signal lifetime
(`epochTimestampExpireConversation` = 10 min) so the published signal expires,
then restore. Both peers must republish a fresh signal and re-rendezvous — no
stale-signal dead-port punch.

## Core path
- Signal expiry on the relay.
- Both peers republish a fresh STUN signal on resume.
- `OrcConnectionOpener.open()` re-dial toward the live mapping.

## Actions wiring
- `side=b-only` (responder on the runner), initiator local.
- The local peer cuts its own link for > 10 min, then restores. The runner just
  waits — so set the runner job `timeout-minutes` to comfortably exceed the
  outage + reconnect (e.g. 25–30).
- `NAT_SCENARIO=long-outage` on both binaries.

## Asserts (strict)
- Reconnect succeeds even though the old signal is gone.
- No punch toward the stale/dead port (no wasted dial cycle on expired signal).
- `postReconnectHeartbeats` acked after resume.

## Metric line
`long-outage outageMs=<n> reconnectTimeMs=<n> messagesLost=<x>/<total>`

## Runner caveats
- A runner idling >10 min consumes paid minutes — run this on demand
  (`workflow_dispatch`), not on every push.
- Do NOT use fresh identities to dodge the expiry — that defeats the scenario.
