# TODO — mtu-edge

**Scenario**: `NAT_SCENARIO=mtu-edge`
**CI fit**: ✅ MTU change runs ON the Linux runner (it has root)
**Status**: [ ] not started

## Goal
Force a small path MTU and assert chunk sizing stays under the limit and
reassembly is correct — no silent drop of oversized UDP datagrams.

## Core path
- Chunk-size selection in `ErmesService` vs the path MTU.

## Actions wiring
- Put the peer whose MTU is constrained on the runner. Add a step before launch:
  `sudo ip link set dev eth0 mtu ${MTU}`
- `NAT_SCENARIO=mtu-edge`; `MTU` env documents the value.

## Asserts (strict)
- No datagram exceeds the path MTU (no fragmentation-dependent loss).
- Reassembled payloads match their source.

## Metric line
`mtu-edge mtu=<n> maxDatagramBytes=<n> checksumOk=true`

## Runner caveats
- Lowering the primary-interface MTU also affects the runner's relay/STUN path —
  pick an `MTU` small enough to test chunking but large enough that WSS/STUN
  still work (e.g. 1280, the IPv6 minimum).
- Restore the MTU in an `if: always()` step.
