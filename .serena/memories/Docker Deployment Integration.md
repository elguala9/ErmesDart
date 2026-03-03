# Smart Contract Deployment via Docker Compose

## Quick Start (2026-03-03)
```bash
# 1. Start Ganache + Deploy Contract
docker compose -f docker-compose-evm.yml up

# 2. In another terminal, run tests (contract already deployed)
cd packages/ermes_test
dart test
```

## Solution ✅ FIXED (2026-03-03)

**Root Cause**: Docker Compose passing PRIVATE_KEY with quotes included (68 chars = too long for hardhat's 32-byte requirement)

**Fix**: Remove PRIVATE_KEY entirely and use Hardhat's mnemonic fallback:
```yaml
environment:
  RPC_URL: http://ganache:8545
  # PRIVATE_KEY removed - using hardhat config mnemonic fallback
```

Hardhat automatically falls back to mnemonic when PRIVATE_KEY is not set, which matches Ganache's mnemonic exactly.

**Result**: ✅ Deployer works! Contract deployed at `0x5FbDB2315678afecb367f032d93F642f64180aa3`

## Configuration (2026-03-03)
**File**: `docker-compose-evm.yml`

### Services
1. **ganache** - Ethereum test network (port 9545)
2. **signaling-contract-deployer** - Deploys SignalingContract to Ganache
   - Image: `elguala96/signaling-contract-deployer:v1.0.1 (tag must have 'v' prefix)`
   - Depends on: Ganache (waits for healthcheck)
   - RPC_URL: `http://ganache:8545` (internal Docker network)
   - Private Key: Account 0 from Ganache's deterministic mnemonic
   - Restart: `no` (runs once, then exits)

### How It Works
```bash
docker compose -f docker-compose-evm.yml up

# Sequence:
# 1. Ganache starts, waits for healthcheck (up to 50s)
# 2. Deployer waits for Ganache healthy status
# 3. Deployer compiles and deploys contract
# 4. Deployer outputs contract address and exits
# 5. Ganache continues running for tests
```

### Test Integration
When running tests, the contract is already deployed:
- Ganache continues running at http://localhost:9545
- Tests can immediately use the SignalingContract
- Address printed in deployer logs

### Notes
- Private key is from Ganache's test mnemonic (deterministic, always same address)
- Deployer exits after successful deployment (restart: no)
- No port mapping needed for deployer (internal service)