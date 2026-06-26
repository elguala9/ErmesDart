# TODO — gap-detection

**Scenario**: `NAT_SCENARIO=gap-detection`
**Status**: [ ] not started

## Goal
Induce specific sequence-number gaps and verify the receiver requests the
missing IDs and the sender resends exactly those — the explicit missing-ID
request path, distinct from the time-based outage in `lossless-reconnect`.

## Core path
- `ermes_message_control`: missing-message detection, array-request of missing
  IDs, threshold-based resend.

## Setup
Two PCs. Drop targeted sequence numbers (e.g. via a short flap timed to a known
seq, or an injected drop) rather than a single contiguous outage.

## Steps
1. Establish the connection; send a sequenced stream.
2. Cause non-contiguous gaps (e.g. drop seq 3, 7, 11).
3. Observe the receiver request the missing IDs.
4. Sender resends only those; receiver completes the set.

## Asserts (strict)
- Receiver issues an explicit request for the exact missing IDs.
- Only the missing IDs are resent (no full re-send).
- Final set complete and ordered.

## Metric line
`gap-detection induced=<list> requested=<list> resent=<list> gaps=0`
