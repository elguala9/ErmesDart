#!/bin/bash

# Deploy SignalingContract to Ganache using Node.js directly
# This bypasses the web3dart signature issue by using ethers.js or hardhat

set -e

GANACHE_RPC="http://localhost:9545"
ALICE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

echo "🚀 Deploying SignalingContract..."
echo ""

# Check if Ganache is running
if ! curl -s "$GANACHE_RPC" > /dev/null 2>&1; then
    echo "❌ Ganache not running at $GANACHE_RPC"
    echo "Start it with: docker-compose -f docker-compose-evm.yml up -d"
    exit 1
fi

echo "✅ Ganache is running"
echo ""

# Option 1: Use Node.js with ethers.js (Recommended)
cat > /tmp/deploy.js << 'EOF'
const { ethers } = require("ethers");

const RPC_URL = "http://localhost:9545";
const PRIVATE_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

const SIGNALING_CONTRACT_ABI = [
  "constructor(address owner)"
];

// Minimal SignalingContract bytecode (you need to provide the actual bytecode)
const SIGNALING_CONTRACT_BYTECODE = "0x"; // Replace with actual bytecode

async function deploy() {
  const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
  const signer = new ethers.Wallet(PRIVATE_KEY, provider);

  console.log(`Deploying from: ${signer.address}`);

  // Get balance
  const balance = await provider.getBalance(signer.address);
  console.log(`Account balance: ${ethers.utils.formatEther(balance)} ETH`);

  // Deploy contract
  const factory = new ethers.ContractFactory(SIGNALING_CONTRACT_ABI, SIGNALING_CONTRACT_BYTECODE, signer);
  const contract = await factory.deploy(signer.address);

  console.log(`✅ Contract deployed at: ${contract.address}`);
  console.log(`Set SIGNALING_CONTRACT_ADDRESS=${contract.address} in your tests`);
}

deploy().catch(console.error);
EOF

# Option 2: Use curl + etherscan's signing service (No JavaScript required)
echo "To deploy, use one of these methods:"
echo ""
echo "Option A (Node.js + ethers.js):"
echo "  npm install ethers"
echo "  node /tmp/deploy.js"
echo ""
echo "Option B (Dart + custom signing fix):"
echo "  dart scripts/deploy_with_signing_fix.dart"
echo ""
echo "Option C (Precompiled contract):"
echo "  SIGNALING_CONTRACT_ADDRESS=0x... dart test"
