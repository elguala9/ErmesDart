# TODO — relay-failover

**Scenario**: `NAT_SCENARIO=relay-failover`
**Status**: [ ] not started

## Goal
Kill one relay in `NOSTR_RELAYS` mid-session and assert rendezvous/reconnect
still works via the remaining relays.

## Core path
- Multi-relay publish/subscribe in the signaling layer.
- Reconnect path falling back to surviving relays.

## Setup
Two PCs. `NOSTR_RELAYS` lists several relays. Make one unreachable mid-run
(block it via firewall/hosts, or point to a relay you can stop).

## Steps
1. Establish the connection across multiple relays.
2. Make one relay unreachable.
3. Force a reconnect (network change) and verify rendezvous via the others.

## Asserts (strict)
- Reconnect succeeds with one relay down.
- No hang waiting on the dead relay (bounded by timeout).

## Metric line
`relay-failover relaysTotal=<n> relaysDown=<n> reconnectTimeMs=<n>`
