# TODO — dual-net-change

**Scenario**: `NAT_SCENARIO=dual-net-change`
**Status**: [ ] not started

## Goal
Both peers change network at the same time (two new NAT mappings at once —
worst case for rendezvous). Verifies the synchronized dial-window rendezvous
still converges.

## Core path
- Both sides republish a fresh signal and re-dial.
- Window alignment (`windowPeriodSeconds` / `windowOpenSeconds`) keeps the two
  dials in the same slot even when both endpoints moved.

## Setup
Two PCs, each able to swap its network (WiFi↔tethering, or two bridges in the
container driver). Trigger both swaps within the same window.

## Steps
1. Establish the steady heartbeat.
2. Swap both peers' networks simultaneously.
3. Both re-rendezvous; heartbeat resumes.

## Asserts (strict)
- Rendezvous converges despite both mappings changing.
- Resume within an extended `reconnectBudget` (allow extra windows).
- Zero loss after resume.

## Metric line
`dual-net-change reconnectTimeMs=<n> windowsUsed=<n> messagesLost=<x>/<total>`
