# TODO — group-churn

**Scenario**: `NAT_SCENARIO=group-churn`
**CI fit**: ✅ 3+ jobs; churn the LOCAL peer so the others stay untouched
**Status**: [ ] not started

## Goal
In a group of 3+ peers, one peer leaves and rejoins while the others keep
exchanging. Asserts the remaining peers are unaffected and the returning peer
re-integrates.

## Core path
- Independent per-peer connections: one teardown/reconnect must not disturb the
  others.

## Actions wiring
- Run the two stable peers on runners (`peer-a`/`peer-b` jobs) and the **churn
  node locally**, so you control its leave/rejoin without touching the runner
  jobs. Reuse `alice/bob/charlie_main.dart`; `NAT_SCENARIO=group-churn`.
- The local churn node leaves (graceful or SIGKILL) then rejoins with the same
  identity.

## Asserts (strict)
- Non-churning pairs show zero loss / no disconnect during the churn.
- Churn node re-establishes its connections on rejoin.

## Metric line
`group-churn peers=<n> unaffectedPairs=<n>/<n> rejoinTimeMs=<n>`

## Runner caveats
- The two runner jobs must stay alive across the churn window — size
  `timeout-minutes` for leave + rejoin + re-integration.
- Distinct identities per peer; mind the `concurrency` group.
