# TODO — gap-detection

**Scenario**: `NAT_SCENARIO=gap-detection`
**CI fit**: ✅ targeted drops produced on the LOCAL peer
**Status**: [x] implemented (engine in ermes_test_shared, NAT_SCENARIO dispatch wired)

## Goal
Induce specific sequence-number gaps and verify the runner requests the missing
IDs and the sender resends exactly those — the explicit missing-ID request
path, distinct from the time-based outage in `lossless-reconnect`.

## Core path
- `ermes_message_control`: missing-message detection, array-request of missing
  IDs, threshold-based resend.

## Actions wiring
- `side=b-only` (receiver on the runner), sender local.
- The local sender drops targeted sequence numbers (e.g. skip emitting seq
  3, 7, 11, or drop them at the socket) rather than a contiguous outage.
- `NAT_SCENARIO=gap-detection` on both binaries.

## Asserts (strict)
- Runner issues an explicit request for the exact missing IDs.
- Only the missing IDs are resent (no full re-send).
- Final set complete and ordered.

## Metric line
`gap-detection induced=<list> requested=<list> resent=<list> gaps=0`
