# NAT & Latency Testing for ErmesDart Peer Node

This document guides testing of the newly implemented NAT simulation and latency tracking features.

## Features Implemented

### 1. Latency Tracking (Always Active)
- **File**: `packages/ermes_peer_node/bin/main.dart`
- **How it works**:
  - Timestamps are added to each message at send time (`sent_at_ms`)
  - Receive time is captured when message arrives
  - Latency = `receive_time - send_time`
  - 95th percentile latency calculated for statistical summary
- **Output**: Results saved to `test_results/<peer>_result.json` with `latency_stats` field

### 2. Latency Injection via tc netem (Optional)
- **File**: `scripts/entrypoint-peer.sh` + `Dockerfile.peer`
- **How it works**:
  - Environment variables control network conditions:
    - `NETWORK_LATENCY_MS` — mean latency in milliseconds (e.g., `50`)
    - `NETWORK_JITTER_MS` — jitter variance (default: `5`)
    - `NETWORK_PACKET_LOSS_PERCENT` — packet loss percentage (default: `0`)
  - Applied via Linux `tc netem` in container entrypoint (requires `iproute2`)
- **Compatibility**: When env vars not set, runs normally (no latency injection)

### 3. NAT Simulation (Separate Docker Compose)
- **File**: `docker-compose-test-peers-nat.yml`
- **Topology**:
  - **Public Network** (172.30.0.0/24): Ganache, STUN server, NAT router
  - **Zone A** (172.30.10.0/24): Alice + Charlie (behind NAT)
  - **Zone B** (172.30.20.0/24): Bob + Dave (behind NAT)
  - **Router**: Masquerade NAT between zones (forces STUN-based IP discovery)
- **Configuration**: Peers use static IPs with `NETWORK_LATENCY_MS: "50"` preset

---

## Test Scenarios

### Test 1: Baseline Latency Tracking (Existing Compose)

**Goal**: Verify latency tracking works with flat docker bridge (no NAT).

```bash
# Clear previous results
rm -f test_results/*.json

# Run existing test infrastructure
docker compose -f docker-compose-test-peers.yml up --build

# Wait for completion (all peers exit)
# View results
cat test_results/alice_result.json | jq .latency_stats

# Expected output:
# {
#   "count": 9,
#   "min_ms": 2.0,
#   "max_ms": 45.0,
#   "avg_ms": 15.0,
#   "p95_ms": 35.0
# }
```

**Success criteria**:
- ✅ All 4 peers report exit code 0
- ✅ `latency_stats` field present in all JSON results
- ✅ Avg latency < 50ms (no artificial delay on flat bridge)

---

### Test 2: Latency Injection Verification

**Goal**: Verify `tc netem` injection works by adding 50ms delay.

```bash
# Modify docker-compose-test-peers.yml temporarily:
# Add to each peer service:
#   environment:
#     NETWORK_LATENCY_MS: "50"
#     NETWORK_JITTER_MS: "10"

# Run test
docker compose -f docker-compose-test-peers.yml up --build
cat test_results/alice_result.json | jq .latency_stats.avg_ms

# Expected: avg_ms ≈ 50 (±20 due to jitter)
```

**Success criteria**:
- ✅ All peers still succeed (exit code 0)
- ✅ Avg latency increases to ~50ms (confirms tc netem applied)

---

### Test 3: NAT Simulation Full Test

**Goal**: Verify peers can communicate through NAT with STUN-based discovery.

```bash
# Clear results
rm -f test_results/*.json

# Run NAT topology
docker compose -f docker-compose-test-peers-nat.yml up --build

# Monitor peer startup (watch container logs)
# Wait for all peer containers to exit (will take 2-3 minutes)

# Check results
for peer in alice bob charlie dave; do
  echo "=== $peer ==="
  cat test_results/${peer}_result.json | jq '{success, received_messages: .received_messages, expected_messages: .expected_messages, latency_stats: .latency_stats}'
done
```

**Expected output**:
```json
{
  "success": true,
  "received_messages": 9,
  "expected_messages": 9,
  "latency_stats": {
    "count": 9,
    "min_ms": 45.0,
    "max_ms": 180.0,
    "avg_ms": 105.0,
    "p95_ms": 165.0
  }
}
```

**Success criteria**:
- ✅ All 4 peers report `success: true`
- ✅ Each peer received all 9 expected messages
- ✅ Latency stats show ~50ms per peer (×2 for RTT ≈ 100ms avg)
- ✅ All peers exit code 0

---

## Troubleshooting

### Container fails with "tc: command not found"
- **Cause**: `iproute2` not installed in Dockerfile
- **Fix**: Verify `Dockerfile.peer` includes `iproute2` in apt-get install

### STUN discovery fails in NAT mode
- **Cause**: Peer cannot reach STUN server (network misconfiguration)
- **Verification**: `docker exec ermes-nat-peer-alice ping 172.30.0.20`
- **Fix**: Check docker network configuration and router iptables rules

### Messages not arriving in NAT mode
- **Cause**: Port mapping or NAT rule issue
- **Debug**:
  ```bash
  # Check router NAT rules are active
  docker exec ermes-nat-router iptables -t nat -L POSTROUTING
  
  # Check peer can reach router gateway
  docker exec ermes-nat-peer-alice ping 172.30.10.1
  ```

### Latency stats show zero/missing
- **Cause**: Messages received before sender added timestamp (clock skew)
- **Verification**: Check peer logs for timestamp parsing errors
- **Expected**: Latency stats present if even one message has both send_time and receive_time

---

## Files Modified / Created

| File | Type | Purpose |
|------|------|---------|
| `packages/ermes_peer_node/bin/main.dart` | MODIFY | Added `LatencyStats` class + timestamp tracking |
| `Dockerfile.peer` | MODIFY | Added `iproute2` + entrypoint script |
| `scripts/entrypoint-peer.sh` | CREATE | Applies tc netem if env vars set |
| `docker-compose-test-peers-nat.yml` | CREATE | NAT topology with 3 networks + router |
| `packages/ermes_peer_node/config/test_config_nat.json` | CREATE | Config with longer timeouts for NAT |

---

## Performance Notes

### Typical Latencies
- **Flat bridge (no NAT)**: 2-20ms avg
- **50ms injected**: ~50ms avg (±20ms jitter)
- **NAT topology**: 50-120ms avg (router latency × 2 + peer delay)

### Scaling Notes
- Router CPU: negligible impact (simple iptables forwarding)
- Memory: ~50MB per container
- Network: full-duplex, all peers can send/recv simultaneously
- Test duration: ~2-3 minutes for full 4-peer, 36-message scenario

---

## Next Steps

1. **Run Test 1** (baseline) to establish baseline latencies
2. **Run Test 2** (latency injection) to verify tc netem works
3. **Run Test 3** (full NAT) to verify STUN-based discovery and routing
4. **Compare results**: NAT should succeed with ~2× latency vs baseline

