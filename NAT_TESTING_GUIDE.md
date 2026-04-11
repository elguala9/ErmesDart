# NAT Types Testing Guide — ErmesDart P2P

Complete test suite for all 4 NAT types with automatic diagnostics and reporting.

## Overview

This guide covers testing ErmesDart P2P under different NAT conditions:

| NAT Type | Compose File | Router Script | Expected | Real-World % |
|----------|------|------|------|---|
| **Full Cone** | `docker-compose-nat-fullcone.yml` | `router-entrypoint-fullcone.sh` | ✅ PASS (exit 0) | ~20% |
| **Address-Restricted** | `docker-compose-nat-addressrestricted.yml` | `router-entrypoint-addressrestricted.sh` | ⚠️ MIXED (partial fail) | ~30% |
| **Port-Restricted** | `docker-compose-nat-portrestricted.yml` | `router-entrypoint-portrestricted.sh` | ⚠️ MIXED (mostly fail) | ~20% |
| **Symmetric** | `docker-compose-nat-symmetric.yml` | `router-entrypoint-symmetric.sh` | ❌ FAIL (exit 1) | ~30% |

---

## Quick Start

### Run All 4 NAT Tests (Sequential)

```bash
# Linux/Mac
bash scripts/test-all-nat-types.sh

# Windows (via WSL or Git Bash)
bash scripts/test-all-nat-types.sh
```

**Duration**: ~15-20 minutes (4 tests × 3-5 min each + build time)

**Output**:
- `nat-test-results.txt` — Summary of all exit codes
- `nat-fullcone-*.log` — Logs for each peer
- `nat-addressrestricted-*.log`
- `nat-portrestricted-*.log`
- `nat-symmetric-*.log`

---

## Individual NAT Type Tests

### Test Full Cone NAT (Easiest)

```bash
docker compose -f docker-compose-nat-fullcone.yml up --build
```

**Expected Behavior**:
- ✅ All 36 messages delivered successfully
- ✅ Exit code 0 for all peers (Alice, Bob, Charlie, Dave)
- ✅ STUN discovery works perfectly
- **Typical latency**: 100-150ms (50ms tc netem × 2 peers)

**Why it passes**: Full Cone NAT uses a static port mapping. Once Alice's port 9001 maps to external port 12345, **everyone** can use 172.30.0.1:12345 to reach Alice. STUN discovers this and it's immediately usable.

**Logs to check**:
```
docker logs ermes-nat-fullcone-peer-alice
```

Expected: `✅ ALL CHECKS PASSED`

---

### Test Address-Restricted Cone NAT (Medium Difficulty)

```bash
docker compose -f docker-compose-nat-addressrestricted.yml up --build
```

**Expected Behavior**:
- ⚠️ Mostly successful but may have timing issues
- ⚠️ Some peers might timeout (exit code 1)
- ⚠️ STUN works but inbound is filtered by source IP

**Why it might fail**: The router filters inbound traffic by **source IP only**. If peer A hasn't been contacted yet by peer B, B's inbound traffic is rejected. However, the protocol typically works because:
1. Both peers contact each other (mutual initiation)
2. NAT state is established bidirectionally

**Likely outcome**: 70-90% success (some timing races possible)

---

### Test Port-Restricted Cone NAT (Hard)

```bash
docker compose -f docker-compose-nat-portrestricted.yml up --build
```

**Expected Behavior**:
- ❌ Partial or complete failure
- ❌ Exit code 1 for most/all peers
- ❌ STUN often ineffective (port must match exactly)

**Why it fails**: The router filters by both **source IP AND source port**. STUN discovers a port, but when the peer tries to connect, it might use a different ephemeral port, causing the NAT to reject the return traffic.

**Likely outcome**: 10-30% success (mostly failures)

---

### Test Symmetric NAT (Worst Case)

```bash
docker compose -f docker-compose-nat-symmetric.yml up --build
```

**Expected Behavior**:
- ❌ Almost certain failure
- ❌ Exit code 1 for all peers
- ❌ STUN completely ineffective

**Why it fails completely**: Symmetric NAT randomizes the external port for **each new destination**:
- Alice contacts STUN server → gets 172.30.0.1:12345
- Alice publishes this to blockchain
- Bob tries to connect to 172.30.0.1:12345
- But when Alice contacts Bob, router assigns 172.30.0.1:12346 (different port!)
- Bob's packets arrive at :12345 but Alice is using :12346
- Connection fails ❌

**Likely outcome**: 0-5% success (essentially never works without TURN relay)

---

## Reading the Results

### Results File: `nat-test-results.txt`

```
Test Results
============

Full Cone NAT:
  Alice:   0
  Bob:     0
  Charlie: 0
  Dave:    0
  Expected: ✅ PASS (STUN works perfectly)

Address-Restricted Cone NAT:
  Alice:   0
  Bob:     1
  Charlie: 0
  Dave:    1
  Expected: ⚠️ MIXED (mostly works)

Port-Restricted Cone NAT:
  Alice:   1
  Bob:     1
  Charlie: 1
  Dave:    1
  Expected: ⚠️ MIXED (often fails)

Symmetric NAT:
  Alice:   1
  Bob:     1
  Charlie: 1
  Dave:    1
  Expected: ❌ FAIL (STUN impossible)
```

### Exit Code Legend

| Code | Meaning |
|------|---------|
| **0** | ✅ Success — all 9 expected messages received |
| **1** | ❌ Failure — missing messages, connection errors, or timeouts |

### Peer Logs

Each peer generates detailed logs with timing and message tracking:

```bash
docker logs ermes-nat-fullcone-peer-alice | grep -E "SENT|RECEIVED|VERIFICATION|CHECKS"
```

Expected full-cone output:
```
[Alice] ✅ SENT id=msg-ab-1 to=0x70997... seq=0
[Alice] ✅ SENT id=msg-ab-2 to=0x70997... seq=1
...
[Alice] ✅ RECEIVED id=msg-ba-1 from=0x70997... seq=0: Bob→Alice message 1
[Alice] ✅ RECEIVED id=msg-ba-2 from=0x70997... seq=1: Bob→Alice message 2
...
[Alice] === VERIFICATION SUMMARY ===
[Alice] Expected: 9 messages
[Alice] Received: 9 messages
[Alice] ✅ ALL CHECKS PASSED
```

---

## Analyzing Failures

### Address-Restricted / Port-Restricted Failures

When a peer gets exit code 1:

**Step 1**: Check peer logs
```bash
docker logs ermes-nat-addressrestricted-peer-alice | tail -50
```

**Step 2**: Look for these patterns:

**Pattern A: Connection Timeout**
```
[Alice] Connecting to Bob...
[Alice] [timeout] Connection not established after 10s
[Alice] MISDIRECTED or SPOOFED msg
```
→ Peer couldn't establish connection due to NAT filtering

**Pattern B: Missing Messages**
```
[Alice] === VERIFICATION SUMMARY ===
[Alice] Expected: 9 messages
[Alice] Received: 5 messages
[Alice] Missing: msg-ba-1, msg-ba-2, msg-ca-1
```
→ Some peers couldn't send back (inbound filtered)

**Pattern C: Timeout Window**
```
[Alice] Waiting up to 120s for inbound messages...
[Alice] [timeout] Keepalive expired
```
→ Messages never arrived within the window

### Symmetric NAT Failure (Expected)

```bash
docker logs ermes-nat-symmetric-peer-alice | grep -E "Connecting|VERIFICATION|CHECKS"
```

Expected output:
```
[Alice] Connecting to Bob...
[Alice] [timeout] No response from 172.30.0.1:XXXXX
[Alice] Bob unreachable (STUN discovered address no longer valid)
...
[Alice] === VERIFICATION SUMMARY ===
[Alice] Expected: 9 messages
[Alice] Received: 0 messages
[Alice] ❌ VERIFICATION FAILED
```

---

## Manual Testing (One NAT Type at a Time)

If you want to test just one type and debug more carefully:

### Full Cone NAT (Baseline)

```bash
# Start
docker compose -f docker-compose-nat-fullcone.yml up --build

# In another terminal, monitor Alice
docker logs -f ermes-nat-fullcone-peer-alice

# View all exit codes once done
docker inspect ermes-nat-fullcone-peer-alice --format='{{.State.ExitCode}}'
docker inspect ermes-nat-fullcone-peer-bob --format='{{.State.ExitCode}}'
docker inspect ermes-nat-fullcone-peer-charlie --format='{{.State.ExitCode}}'
docker inspect ermes-nat-fullcone-peer-dave --format='{{.State.ExitCode}}'

# Clean up
docker compose -f docker-compose-nat-fullcone.yml down -v
```

### Symmetric NAT (Stress Test)

```bash
docker compose -f docker-compose-nat-symmetric.yml up --build

# Watch real-time as it fails
docker logs -f ermes-nat-symmetric-peer-alice

# Check router rules (inside the router container)
docker exec ermes-nat-symmetric-router iptables -t nat -L -v -n

# Clean up
docker compose -f docker-compose-nat-symmetric.yml down -v
```

---

## Understanding Why Each Type Behaves Differently

### Full Cone NAT ✅

**NAT Behavior**:
```
Alice (internal) → STUN server
Router: 192.168.1.10:9001 → 172.30.0.1:12345 (STATIC)

Alice (internal) → Bob (172.30.20.11)
Router: 192.168.1.10:9001 → 172.30.0.1:12345 (REUSE SAME PORT)

Bob connects to 172.30.0.1:12345
Router allows it ✅ (no filtering)
```

**Why STUN works**: The discovered port is stable and reusable for all destinations.

### Address-Restricted Cone ⚠️

**NAT Behavior**:
```
Alice initiates to Bob
Router allows return traffic from Bob (address OK)
Router BLOCKS traffic from unknown addresses
```

**Why it's iffy**: If Alice hasn't initiated to Bob yet, Bob's traffic is blocked. However, most protocols work because both sides initiate (mutual connection).

### Port-Restricted Cone ⚠️⚠️

**NAT Behavior**:
```
Alice initiates to Bob:7000
Router allows return traffic ONLY from Bob:7000
Router BLOCKS return traffic from Bob:7001 or other IPs
```

**Why it usually fails**: Even though both sides initiate, if they use different ephemeral ports than STUN discovered, connection fails.

### Symmetric NAT ❌❌❌

**NAT Behavior**:
```
Alice → STUN (3478) = 172.30.0.1:12345
Alice → Bob (9001) = 172.30.0.1:12346 (DIFFERENT PORT!)
Alice → Charlie (9001) = 172.30.0.1:12347 (YET ANOTHER PORT!)

Bob tries to connect to 12345
Router has no state for incoming 12345 (it's for STUN server)
Bob's packet dropped ❌
```

**Why STUN fails completely**: Port is destination-dependent. Discovered port is invalid for peer connections.

---

## Configuration Files

### Timeout Parameters (All Tests)

Located in `packages/ermes_peer_node/config/test_config_nat.json`:

```json
{
  "network": {
    "post_connection_delay_seconds": 5,    // Handshake stabilization
    "keepalive_seconds": 120,              // Inbound message window
    "ganache_retry_count": 30              // Blockchain retries
  }
}
```

For Symmetric NAT specifically (`test_config_nat_symmetric.json`):
```json
{
  "network": {
    "post_connection_delay_seconds": 10,   // Longer handshake wait
    "keepalive_seconds": 180,              // 3-minute window (more time for chaos)
    "ganache_retry_count": 40              // More Ganache robustness
  }
}
```

### Network Conditions

Applied via `tc netem` inside each peer container:

```yaml
environment:
  NETWORK_LATENCY_MS: "50"      # 50ms base delay
  NETWORK_JITTER_MS: "10"       # ±10ms jitter (normal distribution)
```

These simulate realistic ISP/mobile latency on top of NAT traversal overhead.

---

## Troubleshooting

### "Ganache not healthy"

```bash
docker logs ermes-nat-fullcone-ganache
# Wait 30-40 seconds, health checks have long timeout
```

### "All peers stuck waiting for Ganache"

```bash
docker inspect ermes-nat-fullcone-ganache --format='{{.State.Health}}'
# Should be "healthy"
```

### "Port already in use (9545)"

```bash
lsof -i :9545
docker rm -f <container-id>
```

### "Stale Docker state"

```bash
docker system prune -a --volumes
```

---

## Expected Test Matrix (Summary)

| NAT Type | Exit 0 Peers | Exit 1 Peers | Reason |
|----------|---|---|---|
| Full Cone | 4/4 ✅ | 0/4 | No filtering, STUN perfect |
| Address-Restricted | 2-3/4 ⚠️ | 1-2/4 | Some timing races possible |
| Port-Restricted | 0-1/4 ❌ | 3-4/4 | Port mismatch likely |
| Symmetric | 0/4 ❌ | 4/4 | STUN port invalid for peers |

---

## Next Steps

If tests fail as expected:

1. **Address-Restricted Failures**: Acceptable — timing dependent
2. **Port-Restricted Failures**: Expected — STUN insufficient
3. **Symmetric Failures**: Expected — requires TURN fallback (future work)

These test results validate that STUN behavior matches RFC 5780 predictions. Future improvements can include:
- TURN relay fallback
- ICE candidate gathering
- Connection timeout + retry mechanisms
- Stateful firewall bypassing (UPnP/NAT-PMP)

---

## References

- **RFC 5780**: NAT Behavior Classification
- **RFC 5389**: STUN Protocol
- **RFC 5766**: TURN (Traversal Using Relays around NAT)
- **Docker Networking**: https://docs.docker.com/network/
- **iptables NAT**: https://linux.die.net/man/8/iptables
- **tc netem**: https://man7.org/linux/man-pages/man8/tc-netem.8.html
