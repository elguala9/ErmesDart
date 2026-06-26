# TODO — mtu-edge

**Scenario**: `NAT_SCENARIO=mtu-edge`
**Status**: [ ] not started

## Goal
Force a small path MTU and assert chunk sizing stays under the limit and
reassembly is correct — no silent drop of oversized UDP datagrams.

## Core path
- Chunk-size selection in `ErmesService` vs the path MTU.

## Setup
Two PCs (Linux). Lower the interface MTU (`ip link set <if> mtu <n>`) or use
netem to constrain it. `MTU` env documents the value.

## Steps
1. Set a small MTU on the path.
2. Establish the connection; send payloads that would exceed the MTU unchunked.
3. Verify reassembly.

## Asserts (strict)
- No datagram exceeds the path MTU (no fragmentation-dependent loss).
- Reassembled payloads match their source.

## Metric line
`mtu-edge mtu=<n> maxDatagramBytes=<n> checksumOk=true`
