# TODO — latency-jitter

**Scenario**: `NAT_SCENARIO=latency-jitter`
**Status**: [ ] not started

## Goal
Inject high latency and jitter and assert timeouts/backoff tolerate RTT spikes
without false disconnects or duplicate sends.

## Core path
- Timeout/backoff constants in `NatTestProtocol` and the reconnect path.
- Retransmission timers must not fire prematurely under high RTT.

## Setup
Two PCs (Linux). `tc qdisc add dev <if> root netem delay <ms> <jitter>ms`.
`DELAY_MS` / `JITTER_MS` env document the values.

## Steps
1. Apply netem delay+jitter.
2. Establish the connection; run the heartbeat.
3. Observe behaviour under spiky RTT.

## Asserts (strict)
- No false disconnect / spurious re-rendezvous from a latency spike.
- No duplicate delivery from premature retransmission.

## Metric line
`latency-jitter delayMs=<n> jitterMs=<n> falseDisconnects=0 duplicates=0`
