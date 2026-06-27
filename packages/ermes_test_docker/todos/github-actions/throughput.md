# TODO — throughput

**Scenario**: `NAT_SCENARIO=throughput`
**CI fit**: ✅ pure load — no manipulation
**Status**: [ ] not started

## Goal
Sustain a high message rate (N msg/s for M minutes) over real NAT and report
achieved rate, latency distribution and loss.

## Core path
- `ErmesService` send pipeline, buffering (`maxBuffer`), receive callbacks.

## Actions wiring
- `side=b-only` (receiver on the runner), sender local; or `both` for
  Azure↔Azure.
- `NAT_SCENARIO=throughput`; `TARGET_RATE` and `DURATION` env-configurable.

## Asserts (strict)
- Achieved rate ≥ target (within a margin).
- Loss == 0.
- No unbounded memory growth; buffer stays within `maxBuffer`.

## Metric line
`throughput targetRate=<n> achievedRate=<n> p50Ms=<n> p99Ms=<n> lost=<n>`

## Runner caveats
- Runner egress bandwidth and shared-CPU jitter cap the achievable rate — treat
  the runner number as a floor, not the hardware ceiling.
- Keep `DURATION` inside the job `timeout-minutes`.
