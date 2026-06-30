# TODO — throughput

**Scenario**: `NAT_SCENARIO=throughput`
**Status**: [x] implemented (engine in ermes_test_shared, NAT_SCENARIO dispatch wired)

## Goal
Sustain a high message rate (N msg/s for M minutes) over real NAT and report
achieved rate, latency distribution and loss. Stresses the send/receive path
under continuous pressure.

## Core path
- `ErmesService` send pipeline, buffering (`maxBuffer`), receive callbacks.

## Setup
Two PCs. `TARGET_RATE` and `DURATION` env-configurable.

## Steps
1. Establish the connection.
2. Send at `TARGET_RATE` for `DURATION`, sequenced + timestamped.
3. Receiver records arrival times.

## Asserts (strict)
- Achieved rate ≥ target (within a margin).
- Loss == 0.
- No unbounded memory growth; buffer stays within `maxBuffer`.

## Metric line
`throughput targetRate=<n> achievedRate=<n> p50Ms=<n> p99Ms=<n> lost=<n>`
