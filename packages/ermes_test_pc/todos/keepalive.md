# TODO — keepalive

**Scenario**: `NAT_SCENARIO=keepalive`
**Status**: [ ] not started

## Goal
Hold the connection idle for a long period (e.g. 30+ min) with only keepalive
traffic, then resume the exchange. Verifies the NAT mapping survives (or is
refreshed) and resume needs no full re-rendezvous.

## Core path
- Keepalive / mapping-refresh behaviour of the SHSP transport.

## Setup
Two PCs. `IDLE_DURATION` env controls the idle window.

## Steps
1. Establish the connection.
2. Go idle (keepalive only) for `IDLE_DURATION`.
3. Resume the heartbeat.

## Asserts (strict)
- Resume succeeds without a full re-rendezvous (mapping held).
- First post-idle message delivered within the normal RTT, not a reconnect delay.

## Metric line
`keepalive idleMs=<n> resumedWithoutRerendezvous=true firstMsgLatencyMs=<n>`
