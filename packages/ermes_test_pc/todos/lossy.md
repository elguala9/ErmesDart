# TODO — lossy

**Scenario**: `NAT_SCENARIO=lossy`
**Status**: [x] implemented (engine in ermes_test_shared, NAT_SCENARIO dispatch wired)

## Goal
Inject packet loss (e.g. 5–20%) on the path and assert delivery still completes
via retransmission.

## Core path
- `ermes_message_control` retransmission under steady loss (not a clean outage).

## Setup
Two PCs (Linux). Apply loss with `tc qdisc add dev <if> root netem loss <pct>%`.
`LOSS_PCT` env documents the configured value.

## Steps
1. Apply netem loss on one or both peers.
2. Establish the connection; send a sequenced stream.
3. Verify the full sequence eventually arrives.

## Asserts (strict)
- Full sequence delivered despite loss (retransmission compensates).
- No gaps after the stream completes.

## Metric line
`lossy lossPct=<n> sent=<n> delivered=<n> retransmitted=<n> gaps=0`
