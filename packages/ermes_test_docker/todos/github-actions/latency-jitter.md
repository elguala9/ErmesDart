# TODO — latency-jitter

**Scenario**: `NAT_SCENARIO=latency-jitter`
**CI fit**: ✅ netem runs ON the Linux runner (it has root)
**Status**: [ ] not started

## Goal
Inject high latency and jitter and assert timeouts/backoff tolerate RTT spikes
without false disconnects or duplicate sends.

## Core path
- Timeout/backoff constants in `NatTestProtocol` and the reconnect path.
- Retransmission timers must not fire prematurely under high RTT.

## Actions wiring
- Put the degraded peer on the runner. Add a step before launch:
  `sudo tc qdisc add dev eth0 root netem delay ${DELAY_MS}ms ${JITTER_MS}ms`
- `NAT_SCENARIO=latency-jitter`; `DELAY_MS` / `JITTER_MS` document the values.

## Asserts (strict)
- No false disconnect / spurious re-rendezvous from a latency spike.
- No duplicate delivery from premature retransmission.

## Metric line
`latency-jitter delayMs=<n> jitterMs=<n> falseDisconnects=0 duplicates=0`

## Runner caveats
- Added delay also slows relay/STUN — keep `DELAY_MS` below the rendezvous
  timeouts so the connection still establishes.
- Tear the qdisc down in an `if: always()` step.
