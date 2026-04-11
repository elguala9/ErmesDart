# Timing Hypothesis Test — Address-Restricted and Port-Restricted NAT

## 🎯 Hypothesis

**Address-Restricted and Port-Restricted NAT failures in ErmesDart tests are caused by timing race conditions, NOT fundamental NAT limitations.**

## 📋 The Problem

Initial test results show:
- ✅ **Full Cone NAT**: All 4 peers pass (exit code 0)
- ⚠️ **Address-Restricted**: 2-3 peers pass, 1-2 fail (mixed)
- ❌ **Port-Restricted**: 0-1 peers pass, 3-4 fail (mostly fail)

This suggests these NAT types are fundamentally broken for STUN hole-punching. But is it really?

## 🔬 The Theory

### The Race Condition

```
Timeline (with current 5s post_connection_delay):

t=0s    All 4 peers start, read Ganache, discover STUN
        Alice: 172.30.0.1:12345
        Bob: 172.30.0.1:54321
        Charlie: 172.30.0.1:54322
        Dave: 172.30.0.1:54323

t=1s    All peers POST signals to blockchain
        (Alice's signal is at index, Bob's at index, etc.)

t=2s    All peers START reading blockchain in parallel
        Alice reads: Bob is at 172.30.0.1:54321
        Bob reads: Alice is at 172.30.0.1:12345
        Charlie reads: Alice is at 172.30.0.1:12345, Bob is at 172.30.0.1:54321
        Dave reads: All others

t=2.5s  Alice STARTS opening connections SEQUENTIALLY (500ms stagger):
        - Opens connection to Bob (CREATES NAT STATE: Alice→Bob)
        
t=3s    Meanwhile, Bob (PARALLEL) reads blockchain and tries:
        - Connect to Alice at 172.30.0.1:12345
        ❌ PROBLEM: Alice→Bob state created, but Bob→Alice state NOT YET
        Address-Restricted router: "Bob trying to connect? Alice hasn't contacted Bob yet!"
        BLOCKED ❌

t=3.5s  Alice opens connection to Charlie
        
t=4s    Charlie tries to connect to Alice
        ❌ BLOCKED (same reason as Bob)

t=4.5s  Alice opens connection to Dave
        
t=5s    Dave tries to connect to Alice
        ❌ BLOCKED (same reason)

t=5.5s  post_connection_delay_seconds = 5 expires
        Alice now starts sending messages
        But Bob, Charlie, Dave couldn't receive because
        inbound connections were blocked before Alice initiated them

RESULT: Exit code 1 (messages never arrived)
```

### The Fix: Longer post_connection_delay_seconds

With `post_connection_delay_seconds = 20`:

```
t=0s    All peers start
t=1s    All peers POST signals
t=2s    All peers READ signals
t=2.5s  Alice OPENS connections to Bob (creates state)
t=3.5s  Alice OPENS connections to Charlie (creates state)
t=4.5s  Alice OPENS connections to Dave (creates state)
        
        MEANWHILE, on PARALLEL thread:
t=2-4.5s  Bob, Charlie, Dave are trying to connect to Alice
        ❌ STILL BLOCKED at t=2.5s-4.5s (no inbound state yet)
        ✅ But by t=5s, Alice has created states with all
        
t=5s+   Return traffic from Bob/Charlie/Dave now PASSES
        They receive Alice's inbound messages
        NAT state is established bidirectionally
        
t=20s   post_connection_delay_seconds = 20 expires
        BOTH directions have established states
        All messages flow correctly
        
RESULT: Exit code 0 (all messages arrive)
```

## 📊 Test Configuration

### Standard Config (Current)
```json
{
  "post_connection_delay_seconds": 5,
  "keepalive_seconds": 120
}
```
**Duration**: ~130 seconds total
**Expected Address-Restricted**: 2-3/4 success
**Expected Port-Restricted**: 0-1/4 success

### Slow Config (Hypothesis Test)
```json
{
  "post_connection_delay_seconds": 20,
  "keepalive_seconds": 180
}
```
**Duration**: ~210 seconds total
**Expected Address-Restricted**: 4/4 success ✅ (if hypothesis correct)
**Expected Port-Restricted**: 2-4/4 improved (may still fail due to port filtering)

## 🧪 Test Execution

### Script: `scripts/test-timing-hypothesis.sh`

Runs 4 tests in sequence:
1. **Address-Restricted (Standard)** - baseline
2. **Address-Restricted (Slow)** - verify improvement
3. **Port-Restricted (Standard)** - baseline
4. **Port-Restricted (Slow)** - verify improvement

Each test:
- Waits for peer completion
- Collects exit codes
- Extracts logs
- Records results

**Total Duration**: ~15-20 minutes

### Docker Compose Files

Created companion compose files:
- `docker-compose-nat-addressrestricted-slow.yml`
- `docker-compose-nat-portrestricted-slow.yml`

These use:
- `test_config_nat_slow.json` (new config file)
- Same network topology as standard versions
- Same peers and scenarios (36 messages all-to-all)

## 📈 Expected Results

### If Hypothesis is CORRECT (Problem = Timing)

```
Address-Restricted Results:
  Standard:  Alice:0 Bob:1 Charlie:0 Dave:1  (Success: 2/4)
  Slow:      Alice:0 Bob:0 Charlie:0 Dave:0  (Success: 4/4) ✅ IMPROVEMENT!

Port-Restricted Results:
  Standard:  Alice:1 Bob:1 Charlie:1 Dave:1  (Success: 0/4)
  Slow:      Alice:0 Bob:1 Charlie:0 Dave:1  (Success: 2/4) ✅ IMPROVEMENT!
```

**Interpretation**: Timing race condition confirmed. Fix = increase `post_connection_delay_seconds`.

### If Hypothesis is WRONG (Problem = Fundamental NAT)

```
Address-Restricted Results:
  Standard:  Alice:0 Bob:1 Charlie:0 Dave:1  (Success: 2/4)
  Slow:      Alice:0 Bob:1 Charlie:0 Dave:1  (Success: 2/4) ❌ NO CHANGE

Port-Restricted Results:
  Standard:  Alice:1 Bob:1 Charlie:1 Dave:1  (Success: 0/4)
  Slow:      Alice:1 Bob:1 Charlie:1 Dave:1  (Success: 0/4) ❌ NO CHANGE
```

**Interpretation**: Fundamental NAT limitations. Fix = TURN relay or other workaround.

## 🔍 How to Analyze

### Results File

After test completion, check `timing-hypothesis-results.txt`:

```
Address-Restricted (STANDARD):
  Alice:   0
  Bob:     1
  Charlie: 0
  Dave:    1
  Success: 2/4

Address-Restricted (SLOW):
  Alice:   0
  Bob:     0
  Charlie: 0
  Dave:    0
  Success: 4/4

[improvement = 4 - 2 = +2 peers]
```

### Log Files

Detailed per-peer logs:
- `nat-addressrestricted-alice.log`
- `nat-addressrestricted-slow-alice.log`

Look for patterns:
- `MISDIRECTED` → inbound packet arrived but port/address mismatch
- `Connection timeout` → connection attempt failed
- `RECEIVED` → message successfully delivered
- `VERIFICATION SUMMARY` → final count

## 💡 Why This Matters

**If timing is the culprit**:
- ✅ No code changes needed
- ✅ Just tune the config
- ✅ Address-Restricted/Port-Restricted become viable
- ✅ Real-world NAT traversal is possible

**If fundamental NAT limitation**:
- ❌ Need TURN relay or ICE
- ❌ More complex implementation
- ❌ Better fallback strategy needed

## 🎯 Next Steps (Based on Results)

### If Timing Hypothesis Confirmed ✅

1. Update default config:
   ```json
   "post_connection_delay_seconds": 15  // Compromise between test duration and reliability
   ```

2. Update documentation with NAT type compatibility:
   - ✅ Full Cone: Works always
   - ✅ Address-Restricted: Works with proper delay
   - ⚠️ Port-Restricted: Marginal, consider with caution
   - ❌ Symmetric: Needs TURN

3. Create config variants for different use cases:
   - `test_config_nat_fast.json` (5s - for CI/fast testing)
   - `test_config_nat_balanced.json` (15s - production)
   - `test_config_nat_slow.json` (20s - worst-case environments)

### If Timing Hypothesis Rejected ❌

1. Accept these NAT types as fundamentally limited
2. Plan TURN relay implementation
3. Update testing guide with realistic expectations
4. Consider ICE candidate gathering

## 📝 Technical Notes

### Why post_connection_delay_seconds Matters for Address-Restricted

Address-Restricted NAT tracks "has this IP been authorized for inbound?"

The state is created when:
1. Internal host opens outbound connection to remote IP
2. NAT creates mapping: `internal:port ↔ external:port`
3. NAT authorizes inbound from that remote IP

If remote tries inbound BEFORE step 1, it's blocked.

With longer `post_connection_delay_seconds`, Alice (the peer that initiates connections first, per the code) has time to open all connections BEFORE trying inbound, thus pre-authorizing all remote peers.

### Why Port-Restricted is Harder

Port-Restricted adds an extra dimension: not just source IP, but source **port** must match.

Even if timing is perfect:
- Alice contacts Bob at his SHSP port (9002)
- NAT authorizes return traffic from (Bob's_IP, 9002)
- But Alice might respond from a different port if ephemeral
- Return traffic could be rejected if port doesn't match

This is why Port-Restricted might improve but not fully fix with just timing adjustment.

## 🔗 References

- **RFC 5780**: NAT Behavior Classification and Discovery
- **conntrack**: https://linux.die.net/man/8/conntrack
- **iptables stateful filtering**: https://linux.die.net/man/8/iptables
