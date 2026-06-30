# TODO — lossless-reconnect

**Scenario**: `NAT_SCENARIO=lossless-reconnect`
**Status**: [ ] not started

## Goal
Keep sending sequenced `testData` *during* the outage. After reconnect the
receiver must hold **every** sequence number, in order — proving
retransmission fills the hole created by the break.

## Core path
- `ermes_message_control`: gap detection + retransmission.
- Reconnect path (`handlePeerDisconnect` → `openConnection`).

## Setup
Two PCs. Sender does not pause during the break; it keeps emitting sequenced
messages so some are sent while the link is down.

## Steps
1. Establish the connection; start a monotonically increasing `testData` stream.
2. Break the link mid-stream (messages keep being produced).
3. Restore; let the connection re-rendezvous.
4. Continue until the full sequence is delivered.

## Asserts (strict)
- Receiver's set of sequence numbers has no gaps.
- Order preserved on delivery.
- Retransmission observed for the in-outage sequences.

## Metric line
`lossless-reconnect sent=<n> delivered=<n> retransmitted=<n> gaps=0`
