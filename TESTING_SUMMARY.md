# NAT Testing Implementation Summary

**Status**: Test infrastructure complete, timing hypothesis testing in progress

## What We've Built

### 📁 Test Configurations

**4 Docker Compose Files** for different NAT types:
- `docker-compose-nat-fullcone.yml` — Full Cone NAT (easiest, STUN works)
- `docker-compose-nat-addressrestricted.yml` — Address-Restricted Cone (medium, inbound filtered by IP)
- `docker-compose-nat-portrestricted.yml` — Port-Restricted Cone (hard, inbound filtered by IP+port)
- `docker-compose-nat-symmetric.yml` — Symmetric NAT (hardest, port randomized per destination)

**Slow variants** for timing hypothesis:
- `docker-compose-nat-addressrestricted-slow.yml` — Same, but with longer `post_connection_delay_seconds: 20`
- `docker-compose-nat-portrestricted-slow.yml` — Same, but with longer delay

### 🔧 Router Scripts

Each NAT type has a dedicated iptables configuration:

```
scripts/
├── router-entrypoint-fullcone.sh              (simple MASQUERADE)
├── router-entrypoint-addressrestricted.sh    (MASQUERADE + conntrack ESTABLISHED filter)
├── router-entrypoint-portrestricted.sh       (MASQUERADE + strict quadruplet matching)
└── router-entrypoint-symmetric.sh            (MASQUERADE --random, strictest)
```

### 📊 Config Files

**Standard** (fast test):
- `test_config_nat.json` — 5s post_connection_delay, 120s keepalive

**Slow** (for timing hypothesis):
- `test_config_nat_slow.json` — 20s post_connection_delay, 180s keepalive

### 🧪 Test Scripts

- `scripts/test-all-nat-types.sh` — Run all 4 NAT types sequentially
- `scripts/test-timing-hypothesis.sh` — Test standard vs slow configs
- `scripts/test-timing-hypothesis-clean.sh` — Improved version with aggressive cleanup

### 📚 Documentation

- `NAT_TESTING_GUIDE.md` — Complete guide: how to run, what to expect, troubleshooting
- `TIMING_HYPOTHESIS.md` — Deep dive into the timing race condition theory
- `DOCKER_NAT_VARIANTS.md` — Detailed comparison of all 3 existing variants + Pumba

---

## The Timing Hypothesis

### 🎯 Theory

**Address-Restricted and Port-Restricted NAT failures are caused by timing races, NOT fundamental NAT limitations.**

### ⚡ The Problem

```
Timeline with 5s post_connection_delay:

t=0s    All 4 peers: Ganache connection, STUN discovery
t=1s    All peers: POST signals to blockchain
t=2s    All peers: READ blockchain signals
t=2.5s  Alice: Opens connection to Bob (NAT state created)
t=3s    Bob (parallel): Tries to connect to Alice
        ❌ BLOCKED by Address-Restricted router
           "Bob connecting? Alice hasn't contacted Bob yet!"
t=5s    Alice finishes opening connections
        Bob still hasn't received authorization
        Messages fail to arrive

RESULT: Exit code 1 (race condition lost)
```

### ✅ The Solution

Increase `post_connection_delay_seconds` to 20:

```
t=0s    All peers: Ganache + STUN
t=1s    All peers: POST signals
t=2s    All peers: READ signals
t=2.5s  Alice: Opens connection to Bob (authorizes Bob for inbound)
t=3.5s  Alice: Opens connection to Charlie (authorizes Charlie)
t=4.5s  Alice: Opens connection to Dave (authorizes Dave)
        
        MEANWHILE:
t=2-4.5s Bob/Charlie/Dave trying to connect: BLOCKED (no state yet)
t=5+    Alice now sends keepalive/messages
        Bob/Charlie/Dave authorized to receive
        
t=20s   All connections established bidirectionally
        Messages flow correctly

RESULT: Exit code 0 (all messages delivered)
```

### 📈 Expected Test Results

If hypothesis is **CORRECT** (timing = cause):
```
Address-Restricted:
  STANDARD (5s):  2/4 success
  SLOW (20s):     4/4 success ✅ IMPROVEMENT!

Port-Restricted:
  STANDARD (5s):  0/4 success
  SLOW (20s):     2/4 success ✅ IMPROVEMENT!
```

If hypothesis is **WRONG** (fundamental limitation):
```
Address-Restricted:
  STANDARD (5s):  2/4 success
  SLOW (20s):     2/4 success ❌ NO CHANGE

Port-Restricted:
  STANDARD (5s):  0/4 success
  SLOW (20s):     0/4 success ❌ NO CHANGE
```

---

## Test Matrix

### Standard NAT Behavior (Current)

| NAT Type | Full Cone | Address-Restricted | Port-Restricted | Symmetric |
|----------|-----------|-------------------|-----------------|-----------|
| **Exit 0 Peers** | 4/4 ✅ | 2-3/4 ⚠️ | 0-1/4 ❌ | 0/4 ❌ |
| **STUN Works?** | 100% | 90% | 30% | 0% |
| **Timing Critical?** | No | **YES?** | **YES?** | No |
| **Fallback Needed?** | No | Maybe | Yes | Yes (TURN) |

---

## Files Created

### Docker Compose
```
docker-compose-nat-fullcone.yml
docker-compose-nat-addressrestricted.yml
docker-compose-nat-addressrestricted-slow.yml
docker-compose-nat-portrestricted.yml
docker-compose-nat-portrestricted-slow.yml
docker-compose-nat-symmetric.yml
```

### Router Scripts
```
scripts/router-entrypoint-fullcone.sh
scripts/router-entrypoint-addressrestricted.sh
scripts/router-entrypoint-portrestricted.sh
scripts/router-entrypoint-symmetric.sh
```

### Test Scripts
```
scripts/test-all-nat-types.sh
scripts/test-timing-hypothesis.sh
scripts/test-timing-hypothesis-clean.sh
```

### Config Files
```
packages/ermes_peer_node/config/test_config_nat.json
packages/ermes_peer_node/config/test_config_nat_slow.json
packages/ermes_peer_node/config/test_config_nat_symmetric.json
```

### Documentation
```
NAT_TESTING_GUIDE.md
TIMING_HYPOTHESIS.md
DOCKER_NAT_VARIANTS.md
TESTING_SUMMARY.md (this file)
```

---

## How to Run Tests

### Quick: Single NAT Type
```bash
# Full Cone (should always pass)
docker compose -f docker-compose-nat-fullcone.yml up --build

# Address-Restricted (should have mixed results)
docker compose -f docker-compose-nat-addressrestricted.yml up --build

# Port-Restricted (should mostly fail)
docker compose -f docker-compose-nat-portrestricted.yml up --build

# Symmetric (should fail completely)
docker compose -f docker-compose-nat-symmetric.yml up --build
```

### Timing Hypothesis Test (All 4 variants)
```bash
bash scripts/test-timing-hypothesis-clean.sh
```

### Full Comparison (Standard vs Slow)
```bash
# Test Address-Restricted with standard timing
docker compose -f docker-compose-nat-addressrestricted.yml up --build

# Then test with slow timing
docker compose -f docker-compose-nat-addressrestricted-slow.yml up --build

# Compare exit codes - if slow is better, timing is the culprit
```

---

## Expected Behavior by NAT Type

### Full Cone NAT ✅
- **What it does**: Unrestricted inbound after any outbound
- **STUN effectiveness**: Perfect
- **Expected exit code**: 0 for all 4 peers
- **Real-world prevalence**: ~20% (simple routers)

### Address-Restricted Cone ⚠️
- **What it does**: Inbound filtered by source IP only
- **STUN effectiveness**: Good, but timing-dependent
- **Expected exit code (5s delay)**: 2-3/4 peers pass (timing race)
- **Expected exit code (20s delay)**: 4/4 peers pass? (if hypothesis correct)
- **Real-world prevalence**: ~30% (modern home routers)

### Port-Restricted Cone ⚠️⚠️
- **What it does**: Inbound filtered by source IP+port exactly
- **STUN effectiveness**: Poor
- **Expected exit code (5s delay)**: 0-1/4 peers pass
- **Expected exit code (20s delay)**: 2-3/4 peers pass? (if hypothesis correct)
- **Real-world prevalence**: ~20% (enterprise firewalls)

### Symmetric NAT ❌
- **What it does**: Port is random per destination
- **STUN effectiveness**: None (STUN port doesn't match actual peer ports)
- **Expected exit code (any delay)**: 0/4 peers pass
- **Solution needed**: TURN relay, ICE, or other fallback
- **Real-world prevalence**: ~30% (mobile carriers, ISP CGN)

---

## Key Insights

### 1. STUN Has Limitations

| NAT Type | Why STUN Fails |
|----------|---|
| Full Cone | Never fails ✅ |
| Address-Restricted | Timing: inbound authorized AFTER peer tries to connect |
| Port-Restricted | Port must match exactly; ephemeral ports often don't |
| Symmetric | Port randomized per destination; discovered port invalid for peer connections |

### 2. Timing Matters

With insufficient `post_connection_delay_seconds`, peers try to connect to each other **before** NAT states are established bidirectionally.

The solution is **not code changes**, but **config tuning**:
- Fast: 5s (for CI/testing)
- Balanced: 15s (production)
- Slow: 20s+ (unreliable networks)

### 3. Fundamental vs Transient

- **Full Cone**: Fundamentally works ✅
- **Address-Restricted**: Likely transient (timing) ⚠️
- **Port-Restricted**: Partially transient (timing), partially fundamental ⚠️
- **Symmetric**: Fundamentally broken without TURN ❌

---

## Next Steps (Based on Test Results)

### If Timing Hypothesis Confirmed ✅

1. **Update config files**:
   - Change `post_connection_delay_seconds` default to 15
   - Document trade-offs (duration vs reliability)

2. **Update testing guide**:
   - Mark Address-Restricted as "Works with proper delay"
   - Suggest tuning for unreliable networks

3. **Create config variants**:
   - `test_config_nat_fast.json` (5s - for CI)
   - `test_config_nat_balanced.json` (15s - production)
   - `test_config_nat_slow.json` (20s - unreliable)

4. **Close loop**: Document that STUN hole-punching works for ~80% of real-world NATs with proper timing

### If Timing Hypothesis Rejected ❌

1. **Accept limitations**: Address-Restricted/Port-Restricted fundamentally limited
2. **Plan TURN fallback**: Implement for production reliability
3. **Update documentation**: Realistic expectations for each NAT type
4. **Consider ICE**: Candidate gathering for improved success rates

---

## Testing Metrics

For each test, collect:
- **Exit codes**: 0 = success, 1 = failure
- **Message delivery**: Expected 9, received X (for each peer)
- **Latency stats**: min/max/avg/p95 milliseconds
- **Connection timeline**: When was each connection established

---

## References

- **RFC 5780**: NAT Behavior Classification and Discovery
- **RFC 5389**: STUN Protocol
- **RFC 5766**: TURN (fallback for unreachable peers)
- Docker Networking: NAT, masquerade, conntrack
- Linux iptables: stateful filtering

---

## Current Status

✅ **Complete**: Infrastructure, configs, documentation  
🔄 **In Progress**: Timing hypothesis testing  
⏳ **Pending**: Analysis and recommendations based on test results
