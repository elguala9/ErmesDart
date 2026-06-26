# TODO — nat-type-matrix (cross-cutting)

**Scenario**: not a single binary — run other scenarios across NAT pairs.
**Status**: [ ] not started

## Goal
Run the core scenarios (at least the default exchange and `network-change`)
across NAT-type combinations and record which pass. Tracking task, not new code.

## Combinations to record
- [ ] cone ↔ cone — expected PASS
- [ ] cone ↔ symmetric
- [ ] symmetric ↔ symmetric — expected FAIL until TURN
- [ ] CGNAT / mobile 4G-5G — expected FAIL until TURN
- [ ] IPv6 ↔ IPv6
- [ ] IPv4 ↔ IPv6

## How
- Pick networks of the right NAT type (home router = cone; mobile = CGNAT/sym).
- Identify NAT type per endpoint (e.g. a STUN NAT-behaviour probe).
- Run the scenario, capture stdout, note PASS/FAIL + NAT type per side.

## Output
Append a results table to `../NAT_TEST.md`: date, scenario, NAT type A, NAT type
B, result, notes. Document the TURN gap where symmetric/CGNAT fails.
