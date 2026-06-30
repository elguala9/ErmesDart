# TODO — peer-restart

**Scenario**: `NAT_SCENARIO=peer-restart`
**CI fit**: ✅ kill/restart the LOCAL peer; the runner is the stable survivor
**Status**: [x] implemented, not yet run in CI

## Goal
Hard-kill the local peer mid-exchange and restart it with the **same
identity**; the runner (survivor) must detect the drop and the restarted local
peer must rejoin and resume.

## Core path
- Survivor (runner): `handlePeerDisconnect()` on the silent drop, backoff +
  `openConnection()` retry.
- Restarted peer (local): fresh process, same Nostr identity, re-rendezvous.

## Actions wiring
- `side=b-only` (survivor/responder on the runner), moving peer local.
- A local wrapper (shell loop / driver) SIGKILLs `nat_peer_a` and relaunches it
  with identical env (`NOSTR_PRIVKEY/PUBKEY`). Killing the **local** side avoids
  needing process control inside the runner job.
- `NAT_SCENARIO=peer-restart` on both binaries.

## Asserts (strict)
- Runner survivor logs `handlePeerDisconnect`.
- New connection established; heartbeat resumes within `reconnectBudget`.
- No duplicate connection lingers for the dead process.

## Metric line
`peer-restart rejoinTimeMs=<n> messagesLost=<x>/<total>`

## Runner caveats
- The runner job must outlive the local restart gap — keep `timeout-minutes`
  generous enough for kill + relaunch + re-rendezvous.
