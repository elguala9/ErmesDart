# TODO — lossless-reconnect

**Scenario**: `NAT_SCENARIO=lossless-reconnect`
**CI fit**: ✅ outage produced on the LOCAL peer while it keeps sending
**Status**: [ ] not started

## Goal
Keep sending sequenced `testData` *during* an outage. After reconnect the
runner must hold **every** sequence number, in order — proving retransmission
fills the hole.

## Core path
- `ermes_message_control`: gap detection + retransmission.
- Reconnect path (`handlePeerDisconnect` → `openConnection`).

## Actions wiring
- `side=b-only` (receiver/responder on the runner), sender local.
- The local sender does NOT pause during the break; it keeps emitting sequenced
  messages while the outbound UDP path is dropped, then restored.
- `NAT_SCENARIO=lossless-reconnect` on both binaries.

## Asserts (strict)
- Runner's set of sequence numbers has no gaps.
- Order preserved on delivery.
- Retransmission observed for the in-outage sequences.

## Metric line
`lossless-reconnect sent=<n> delivered=<n> retransmitted=<n> gaps=0`
