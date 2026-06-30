# TODO — star-topology

**Scenario**: `NAT_SCENARIO=star-topology`
**Status**: [ ] not started

## Goal
One hub peer with N spoke peers on separate machines. Mirrors the in-process
star-topology test (`multi_peer_integration_test.dart`) over real NAT.

## Core path
- Hub holding N simultaneous connections (`ErmesConnectionsHandler`).
- `getConnections()` settling to N.

## Setup
1 hub PC + N spoke PCs/CI runners. Hub role drives, spokes respond.

## Steps
1. Each spoke rendezvous with the hub.
2. Hub exchanges a heartbeat with every spoke concurrently.

## Asserts (strict)
- Hub's `getConnections()` settles to exactly N.
- Each spoke exchange completes with zero loss.
- No spoke starves another (all make progress).

## Metric line
`star-topology spokes=<N> connected=<N> messagesLost=<x>/<total>`
