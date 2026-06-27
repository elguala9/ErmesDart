# TODO — keepalive

**Scenario**: `NAT_SCENARIO=keepalive`
**CI fit**: ⚠️ feasible — keep the idle window inside the job timeout
**Status**: [ ] not started

## Goal
Hold the connection idle with only keepalive traffic, then resume the exchange.
Verifies the NAT mapping survives (or is refreshed) and resume needs no full
re-rendezvous.

## Core path
- Keepalive / mapping-refresh behaviour of the SHSP transport.

## Actions wiring
- `side=b-only` (responder on the runner), initiator local.
- `NAT_SCENARIO=keepalive`; `IDLE_DURATION` env controls the idle window. On CI,
  keep it modest (e.g. 8–12 min) so the job stays under `timeout-minutes` —
  long enough to outlast typical NAT UDP timeouts, short enough to not burn
  excessive minutes.
- For a true 30+ min soak, run the two-PC version (`../keepalive.md`) instead.

## Asserts (strict)
- Resume succeeds without a full re-rendezvous (mapping held).
- First post-idle message delivered within normal RTT, not a reconnect delay.

## Metric line
`keepalive idleMs=<n> resumedWithoutRerendezvous=true firstMsgLatencyMs=<n>`

## Runner caveats
- The Azure-side NAT timeout may differ from a home router's, so a CI pass does
  not guarantee a home-NAT pass and vice versa — note which NAT held.
