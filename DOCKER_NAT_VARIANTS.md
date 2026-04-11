# Docker NAT Simulation Variants — ErmesDart P2P Testing

**Status**: ✅ Three configurable NAT topologies with chaos engineering support

## Overview

ErmesDart provides three Docker Compose configurations for testing P2P networking under different NAT conditions:

| Config | NAT Type | Chaos Tool | Purpose |
|--------|----------|-----------|---------|
| `docker-compose-test-peers.yml` | **None** (flat bridge) | None | Baseline — no network isolation |
| `docker-compose-test-peers-nat.yml` | **Full Cone NAT** | `tc netem` | STUN should work reliably |
| `docker-compose-test-peers-nat-symmetric.yml` | **Symmetric NAT** | `tc netem` + **Pumba** | Stress test — STUN limited effectiveness |

---

## 1. Baseline: Flat Bridge (No NAT)

**File**: `docker-compose-test-peers.yml`

**Network Topology**:
```
All 4 peers (Alice, Bob, Charlie, Dave) + Ganache + STUN on single bridge network
No isolation, DNS hostname resolution works
```

**When to use**: Fast baseline validation, development, debugging peer protocol logic.

**Run**:
```bash
docker compose -f docker-compose-test-peers.yml up --build
```

**Expected result**: All 36 messages delivered (4 peers × all-pairs bidirectional × 3 messages each). Exit code 0 for all peers.

**Network conditions**: None. Direct reachability.

---

## 2. Full Cone NAT (Realistic Mobile/ISP NAT)

**File**: `docker-compose-test-peers-nat.yml`

**Network Topology**:
```
              Public Network (172.30.0.0/24)
              ├── Ganache (172.30.0.10)
              ├── STUN Server (172.30.0.20)
              └── NAT Router (172.30.0.1)
                  ├── Zone A (172.30.10.0/24)
                  │   ├── Alice (172.30.10.11)
                  │   └── Charlie (172.30.10.12)
                  └── Zone B (172.30.20.0/24)
                      ├── Bob (172.30.20.11)
                      └── Dave (172.30.20.12)
```

**NAT Behavior**: iptables `MASQUERADE` (default)
- Outbound traffic from Zone A/B → NAT router changes source IP to `172.30.0.1`
- Mapped port is **static per peer** (deterministic MASQUERADE)
- STUN returns `172.30.0.1:XXXXX` which is stable for the peer's address
- Remote peers can connect to advertised `172.30.0.1:XXXXX` reliably

**Network Conditions**: `tc netem` inside each peer container
- `NETWORK_LATENCY_MS=50` → 50ms base delay
- `NETWORK_JITTER_MS=10` → ±10ms jitter (normal distribution)
- No packet loss

**When to use**: Standard integration test, realistic ISP/mobile NAT, STUN hole-punching validation.

**Run**:
```bash
docker compose -f docker-compose-test-peers-nat.yml up --build
```

**Expected result**: All 36 messages delivered after STUN negotiation. Exit code 0 for all peers. Median latency ~100ms (50ms tc netem × 2 peers, plus network).

**Config file**: `packages/ermes_peer_node/config/test_config_nat.json`
- `post_connection_delay_seconds: 5` (handshake stabilization)
- `keepalive_seconds: 120` (wait for messages)

---

## 3. Symmetric NAT + Pumba (Stress Test)

**File**: `docker-compose-test-peers-nat-symmetric.yml`

**Network Topology**: Same as Full Cone (3 networks) but with different NAT behavior.

**NAT Behavior**: iptables `MASQUERADE --random`
- Outbound traffic → NAT router applies port randomization
- **Each new connection to a different peer gets a different source port**
- The port is essentially unpredictable (random per destination)
- STUN server returns `172.30.0.1:XXXXX`, but this port is only valid for the STUN server connection
- When Alice tries to connect to Bob, **different port is used → Bob's inbound packets don't reach Alice**

**Chaos Engineering**: **Pumba** injects external packet chaos
- Image: `gaiaadm/pumba:latest`
- Iniects via Docker socket (no need for `NET_ADMIN` in peer containers beyond `tc netem`)
- **30ms additional delay** (on top of tc netem → ~80ms total delay)
- **10ms jitter** (normal distribution)
- **2% packet loss** (tests retransmission behavior)

**Network Conditions**: Combined
1. `tc netem` (50ms delay + 10ms jitter in container)
2. Pumba (30ms delay + 10ms jitter + 2% loss external)
3. Symmetric NAT ephemeral port randomization

**When to use**: Stress testing, verifying STUN limitations, testing fallback mechanisms, chaos engineering validation.

**Run**:
```bash
docker compose -f docker-compose-test-peers-nat-symmetric.yml up --build
```

**Expected result**: **Likely partial or full failure** (exit code 1) due to Symmetric NAT + Pumba chaos.
- Cross-zone peer pairs (Alice↔Bob, Alice↔Dave, Charlie↔Bob, Charlie↔Dave) will struggle because STUN-discovered endpoints become stale after Symmetric NAT port rotation
- Pumba's 2% packet loss will cause retransmissions
- **This is expected behavior** — it demonstrates the limits of STUN in Symmetric NAT environments

**Config file**: `packages/ermes_peer_node/config/test_config_nat_symmetric.json`
- `post_connection_delay_seconds: 10` (longer handshake wait for Pumba disruption)
- `keepalive_seconds: 180` (3 minutes — long window to absorb Pumba chaos)
- `ganache_retry_count: 40` (more Ganache connection retries due to Pumba loss)

**Pumba Service Definition** (in compose file):
```yaml
pumba:
  image: gaiaadm/pumba:latest
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
  command: |
    netem --tc-image gaiaadm/tc:latest
    --duration 300s
    delay --time 30 --jitter 10 --distribution normal
    loss --percent 2
    re2:ermes-nat-symmetric-peer-.*
```

---

## Peer Addresses (All Variants)

All variants use the same Hardhat test accounts:

| Name | Address | Private Key | SHSP Port |
|------|---------|-------------|-----------|
| Alice | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` | 9001 |
| Bob | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` | 9002 |
| Charlie | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a` | 9003 |
| Dave | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` | `0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6` | 9004 |

---

## Message Scenario Matrix

All variants test the same 36-message all-pairs bidirectional matrix:
```
Alice → [Bob, Charlie, Dave] (3 messages each = 9)
Bob   → [Alice, Charlie, Dave] (3 messages each = 9)
Charlie → [Alice, Bob, Dave] (3 messages each = 9)
Dave  → [Alice, Bob, Charlie] (3 messages each = 9)

Total: 36 directed messages, 18 peers pairs, 3 messages per pair
```

Each peer expects 9 inbound messages (3 from each of 3 other peers).

---

## Exit Codes

All variants use exit code semantics:

| Code | Meaning |
|------|---------|
| **0** | ✅ All expected messages received, no errors |
| **1** | ❌ Messages missing, misdirected, spoofed, or network failures |

### Check Exit Codes

**After containers stop** (naturally after `keepalive_seconds` timeout):

```bash
docker inspect ermes-<variant>-peer-alice --format='{{.State.ExitCode}}'
docker inspect ermes-<variant>-peer-bob --format='{{.State.ExitCode}}'
docker inspect ermes-<variant>-peer-charlie --format='{{.State.ExitCode}}'
docker inspect ermes-<variant>-peer-dave --format='{{.State.ExitCode}}'
```

Replace `<variant>` with:
- Nothing (empty) for baseline flat bridge
- `nat` for Full Cone NAT
- `nat-symmetric` for Symmetric NAT + Pumba

---

## Test Results and Logs

### Location
- Container results: `/app/results/<peer_name>_result.json` (inside container)
- Host mount: `./test_results/<peer_name>_result.json`

### Result JSON Schema
```json
{
  "peer_name": "Alice",
  "address": "0xf39fd6e...",
  "expected_messages": 9,
  "received_messages": 9,
  "verification_errors": [],
  "latency_stats": {
    "min_ms": 45,
    "max_ms": 120,
    "avg_ms": 85,
    "p95_ms": 110
  },
  "timestamp_start_iso": "2026-04-10T...",
  "timestamp_end_iso": "2026-04-10T...",
  "duration_seconds": 95
}
```

### Container Logs

Watch real-time logs:
```bash
# Baseline
docker compose -f docker-compose-test-peers.yml logs -f peer-alice

# Full Cone NAT
docker compose -f docker-compose-test-peers-nat.yml logs -f peer-alice

# Symmetric NAT + Pumba
docker compose -f docker-compose-test-peers-nat-symmetric.yml logs -f peer-alice
```

Example log output (all variants):
```
[Alice] Starting — address: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
[Alice] Connected to Ganache
[Alice] Opening 3 connections...
[Alice] Connecting to Bob...
[Alice] Connected to Bob
[Alice] Connecting to Charlie...
[Alice] Connected to Charlie
[Alice] Connecting to Dave...
[Alice] Connected to Dave
[Alice] Waiting for handshakes...
[Alice] Sending 9 messages...
[Alice] ✅ SENT id=msg-ab-1 to=0x70997970c51812dc3a010c7d01b50e0d17dc79c8 seq=0
...
[Alice] Waiting up to 180s for inbound messages...
[Alice] ✅ RECEIVED id=msg-ba-1 from=0x70997970c51812dc3a010c7d01b50e0d17dc79c8 seq=0
...
[Alice] === VERIFICATION SUMMARY ===
[Alice] Expected: 9 messages
[Alice] Received: 9 messages
[Alice] ✅ ALL CHECKS PASSED
```

---

## Cleanup and Restart

### Remove All Containers and Networks

```bash
# Baseline
docker compose -f docker-compose-test-peers.yml down -v
docker network rm ermes-peers-network 2>/dev/null || true

# Full Cone NAT
docker compose -f docker-compose-test-peers-nat.yml down -v
docker network rm ermes-nat-public-net ermes-nat-zone-a ermes-nat-zone-b 2>/dev/null || true

# Symmetric NAT + Pumba
docker compose -f docker-compose-test-peers-nat-symmetric.yml down -v
docker network rm ermes-nat-symmetric-public-net ermes-nat-symmetric-zone-a ermes-nat-symmetric-zone-b 2>/dev/null || true
```

### Full System Cleanup
```bash
docker system prune -a --volumes
```

---

## Troubleshooting

### "Port already in use"
```bash
lsof -i :9545  # Check Ganache port
docker ps -a    # List all containers
docker rm -f <container-id>
```

### Ganache never becomes healthy
- Wait 30-40 seconds (health check has long timeout)
- Check logs: `docker logs ermes-<variant>-ganache`
- Ensure port 9545 is free: `docker ps | grep ganache`

### Peer containers won't start
- Verify Ganache is healthy: `docker ps | grep ganache`
- Check peer logs: `docker logs ermes-<variant>-peer-alice`
- Confirm contract deployer ran: `docker logs ermes-<variant>-contract-deployer`

### All messages missing (exit code 1)
**Flat bridge**: Check peer logs for connection errors
**Full Cone NAT**: Verify STUN server is reachable from peers
**Symmetric NAT + Pumba**: Expected behavior. Check if SHSP protocol has fallback mechanisms

### High latency or timeouts
**Check Pumba** (Symmetric NAT only):
```bash
docker logs ermes-nat-symmetric-pumba
docker exec ermes-nat-symmetric-peer-alice tc qdisc show dev eth0
```

---

## Extending the Tests

### Modify Network Conditions
Edit `NETWORK_LATENCY_MS`, `NETWORK_JITTER_MS` in docker-compose:
```yaml
environment:
  NETWORK_LATENCY_MS: "100"  # 100ms delay
  NETWORK_JITTER_MS: "20"    # 20ms jitter
```

### Modify Pumba Chaos
Edit the `pumba` service command:
```yaml
command: |
  netem --tc-image gaiaadm/tc:latest
  --duration 300s
  delay --time 50 --jitter 15 --distribution normal  # More delay/jitter
  loss --percent 5  # Higher packet loss
  re2:ermes-nat-symmetric-peer-.*
```

### Add Custom Message Scenarios
Edit `packages/ermes_peer_node/config/test_config_*.json`:
```json
{
  "id": "msg-custom-1",
  "from": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
  "to": "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
  "content": "Custom message",
  "sequence": 100
}
```

### Switch Peer Zones (Symmetric NAT only)
Move a peer to different network to test same-zone vs cross-zone:
```yaml
peer-alice:
  networks:
    zone-b-net:  # Move Alice to Zone B (same as Bob)
      ipv4_address: 172.30.20.11
```

---

## Key Differences by Variant

| Aspect | Flat Bridge | Full Cone NAT | Symmetric NAT + Pumba |
|--------|------------|---------------|----------------------|
| **Network Isolation** | None | 3 zones (public + 2 private) | 3 zones (public + 2 private) |
| **NAT Type** | None | Full Cone (static port) | Symmetric (random port) |
| **STUN Effectiveness** | N/A | ✅ Works perfectly | ⚠️ Limited (port rotation) |
| **Latency Injection** | None | 50ms tc netem | 50ms tc + 30ms Pumba |
| **Packet Loss** | None | None | 2% Pumba loss |
| **Typical Duration** | 40-50s | 70-90s | 120-180s (more retries) |
| **Expected Exit Code** | 0 | 0 | Likely 1 (stress test) |

---

## Technical Notes

### Router Implementation (Symmetric NAT)

The router uses Alpine with iptables:
```sh
iptables -t nat -A POSTROUTING -s 172.30.10.0/24 -o eth0 -j MASQUERADE --random
iptables -t nat -A POSTROUTING -s 172.30.20.0/24 -o eth0 -j MASQUERADE --random
```

The `--random` flag randomizes the ephemeral source port for each connection, simulating Symmetric NAT behavior. In production Symmetric NAT, port depends on destination IP; here `--random` is a practical proxy.

### Pumba vs tc netem

- **`tc netem`** (inside container): Applied per-interface, symmetric (affects both inbound+outbound), requires `NET_ADMIN`
- **Pumba** (external): Targets specific containers via Docker socket, can be asymmetric, no `NET_ADMIN` needed in targets

Combined, they simulate more realistic external network chaos (Pumba) on top of internal delays (tc netem).

### SHSP Fallback (Future Enhancement)

With Symmetric NAT, standard STUN hole-punching fails because the port changes per destination. Potential solutions:
1. **ICE candidate gathering** — try multiple address families and ports
2. **TURN relay** — bypass NAT entirely
3. **Connection timeout + retry on different port** — brute-force approach
4. **mDNS or local network discovery** — works within same zone

Current implementation relies on STUN; Symmetric NAT test is a negative test case.

---

## References

- **RFC 5389**: STUN protocol
- **RFC 8489**: STUN extensions (legacy, modern spec)
- **NAT Behavior**: https://www.rfc-editor.org/rfc/rfc5780.html (NAT Behavior Classification)
- **Docker Networking**: https://docs.docker.com/network/
- **Pumba**: https://github.com/gianarb/pumba
- **tc netem**: https://man7.org/linux/man-pages/man8/tc-netem.8.html
