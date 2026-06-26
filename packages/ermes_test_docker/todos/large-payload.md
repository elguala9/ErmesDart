# TODO — large-payload

**Scenario**: `NAT_SCENARIO=large-payload`
**Status**: [ ] not started

## Goal
Sweep payload sizes (1 KB → several MB) and assert correct reassembly and
bounded latency at each size. Validates the chunking pipeline across a range,
without a network break (cf. `fragmented-break`, which adds an outage).

## Core path
- `ErmesService` chunking + `ErmesReadRepo` reassembly across many chunk counts.

## Setup
Two PCs. `SIZES` env lists the payload sizes to sweep.

## Steps
1. Establish the connection.
2. For each size: send one payload, verify reassembly and record latency.

## Asserts (strict)
- Each reassembled payload matches its source (checksum).
- Latency grows sub-quadratically with size (no pathological blowup).

## Metric line
`large-payload sizes=<list> allChecksumsOk=true maxLatencyMs=<n>`
