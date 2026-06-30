# TODO — lossy

**Scenario**: `NAT_SCENARIO=lossy`
**CI fit**: ✅ netem runs ON the Linux runner (it has root)
**Status**: [x] implemented (engine in ermes_test_shared, NAT_SCENARIO dispatch wired)

## Goal
Inject packet loss (e.g. 5–20%) on the path and assert delivery still completes
via retransmission.

## Core path
- `ermes_message_control` retransmission under steady loss (not a clean outage).

## Actions wiring
- Put the **degraded** peer on the runner (Linux + root → `tc`). Run the clean
  peer locally; either side can be initiator/responder.
- Add a workflow step before launching the peer:
  `sudo tc qdisc add dev eth0 root netem loss ${LOSS_PCT}%`
- `NAT_SCENARIO=lossy`; `LOSS_PCT` env documents the configured value.

## Asserts (strict)
- Full sequence delivered despite loss (retransmission compensates).
- No gaps after the stream completes.

## Metric line
`lossy lossPct=<n> sent=<n> delivered=<n> retransmitted=<n> gaps=0`

## Runner caveats
- netem on `eth0` also degrades the runner's relay/STUN traffic — acceptable
  here (whole-path loss is the point), but keep `LOSS_PCT` low enough that
  rendezvous still completes.
- Tear the qdisc down in an `if: always()` step (`tc qdisc del dev eth0 root`).
