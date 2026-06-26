# TODO — group-churn

**Scenario**: `NAT_SCENARIO=group-churn`
**Status**: [ ] not started

## Goal
In a group of 3+ peers, one peer leaves and rejoins while the others keep
exchanging. Asserts the remaining peers are unaffected and the returning peer
re-integrates.

## Core path
- Independent per-peer connections: one teardown/reconnect must not disturb the
  others.

## Setup
3+ PCs (or 2 PCs + CI). One peer is the churning node.

## Steps
1. Establish the group (all pairwise exchanges live).
2. Churn node leaves (graceful or hard) then rejoins with the same identity.
3. Verify the others never stalled and the node re-integrates.

## Asserts (strict)
- Non-churning pairs show zero loss / no disconnect during the churn.
- Churn node re-establishes its connections on rejoin.

## Metric line
`group-churn peers=<n> unaffectedPairs=<n>/<n> rejoinTimeMs=<n>`
