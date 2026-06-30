# TODO — large-payload

**Scenario**: `NAT_SCENARIO=large-payload`
**CI fit**: ✅ pure exchange — no manipulation
**Status**: [ ] not started

## Goal
Sweep payload sizes (1 KB → several MB) and assert correct reassembly and
bounded latency at each size (no network break; cf. `fragmented-break`).

## Core path
- `ErmesService` chunking + `ErmesReadRepo` reassembly across many chunk counts.

## Actions wiring
- `side=b-only` (receiver on the runner), sender local.
- `NAT_SCENARIO=large-payload`; `SIZES` env lists the sizes to sweep.

## Asserts (strict)
- Each reassembled payload matches its source (checksum).
- Latency grows sub-quadratically with size (no pathological blowup).

## Metric line
`large-payload sizes=<list> allChecksumsOk=true maxLatencyMs=<n>`

## Runner caveats
- Latency numbers include the public-relay/Azure path — compare trends across
  sizes, not absolute values against a LAN baseline.
