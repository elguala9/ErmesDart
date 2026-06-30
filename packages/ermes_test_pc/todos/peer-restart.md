# TODO — peer-restart

**Scenario**: `NAT_SCENARIO=peer-restart`
**Status**: [ ] not started

## Goal
Hard-kill one peer mid-exchange and restart it with the **same identity**; the
surviving peer must detect the drop and the restarted peer must rejoin and
resume.

## Core path
- Survivor: `handlePeerDisconnect()` fires on the silent drop, backoff +
  `openConnection()` retry.
- Restarted peer: fresh process, same Nostr identity, re-rendezvous.

## Setup
Two PCs. The moving peer is launched by a wrapper that can SIGKILL and relaunch
it (driver script or a shell loop) keeping the same env identity.

## Steps
1. Establish the steady heartbeat.
2. SIGKILL the responder process while the exchange is live.
3. Relaunch the responder with identical env (`NOSTR_PRIVKEY/PUBKEY`).
4. Both re-rendezvous; heartbeat resumes.

## Asserts (strict)
- Survivor observes the disconnect (logs `handlePeerDisconnect`).
- New connection established; heartbeat resumes within `reconnectBudget`.
- No duplicate connection lingers for the dead process.

## Metric line
`peer-restart rejoinTimeMs=<n> messagesLost=<x>/<total>`
