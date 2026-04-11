#!/bin/bash
set -e

# NAT Types Comprehensive Test Suite
# ===================================
# Tests all 4 NAT types and reports results with exit codes and diagnostics

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "======================================================================"
echo "  ErmesDart P2P NAT Types Test Suite"
echo "======================================================================"
echo ""
echo "Testing: Full Cone | Address-Restricted | Port-Restricted | Symmetric"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configurations
declare -A NAT_TYPES=(
  ["fullcone"]="Full Cone NAT"
  ["addressrestricted"]="Address-Restricted Cone NAT"
  ["portrestricted"]="Port-Restricted Cone NAT"
  ["symmetric"]="Symmetric NAT"
)

declare -A EXPECTED=(
  ["fullcone"]="✅ PASS (STUN works perfectly)"
  ["addressrestricted"]="✅ PASS (NAT traversal works)"
  ["portrestricted"]="✅ PASS (NAT traversal works)"
  ["symmetric"]="⚠️  EXPECTED TO FAIL (STUN impossible with Symmetric NAT)"
)

# Initialize results file
RESULTS_FILE="$REPO_ROOT/nat-test-results.txt"
: > "$RESULTS_FILE"

echo "Test Results" > "$RESULTS_FILE"
echo "============" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# Function to run a single NAT test
run_nat_test() {
  local nat_type=$1
  local nat_name=${NAT_TYPES[$nat_type]}
  local expected=${EXPECTED[$nat_type]}

  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}Testing: $nat_name${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  # Special warning for Symmetric NAT
  if [ "$nat_type" = "symmetric" ]; then
    echo -e "${YELLOW}⚠️  WARNING: Symmetric NAT is known to be extremely difficult for P2P!${NC}"
    echo -e "${YELLOW}    - STUN will fail (randomized port mapping per destination)${NC}"
    echo -e "${YELLOW}    - Hole-punching techniques will not work without TURN relays${NC}"
    echo -e "${YELLOW}    - This test will LIKELY FAIL - this is EXPECTED and OK${NC}"
    echo ""
  fi

  echo ""

  COMPOSE_FILE="$REPO_ROOT/docker-compose-nat-$nat_type.yml"
  CONTAINER_PREFIX="ermes-nat-$nat_type"

  if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}ERROR: Compose file not found: $COMPOSE_FILE${NC}"
    echo "$nat_name: ERROR - File not found" >> "$RESULTS_FILE"
    return 1
  fi

  # Clean up previous containers/networks AGGRESSIVELY
  echo -e "${YELLOW}[1/4] Cleaning up previous containers...${NC}"
  cd "$REPO_ROOT"
  docker compose -f "$COMPOSE_FILE" down -v 2>/dev/null || true

  # Force remove any stale networks from CURRENT test
  for net in $(docker network ls --filter "name=ermes-nat-$nat_type" -q 2>/dev/null); do
    docker network rm "$net" 2>/dev/null || true
  done

  docker system prune -af --volumes 2>/dev/null || true
  docker network prune -f 2>/dev/null || true

  # Wait until all networks are truly gone
  local max_wait=30
  local waited=0
  while docker network ls --filter "name=ermes-nat-$nat_type" -q 2>/dev/null | grep -q . && [ $waited -lt $max_wait ]; do
    sleep 1
    waited=$((waited + 1))
  done

  if [ $waited -gt 0 ]; then
    echo -e "${YELLOW}[*] Waited ${waited}s for networks to be removed${NC}"
  fi
  sleep 2

  # Start the test
  echo -e "${YELLOW}[2/4] Starting Docker Compose...${NC}"
  docker compose -f "$COMPOSE_FILE" up --build 2>&1 | tee "nat-$nat_type-build.log"

  # Wait for containers to finish
  echo -e "${YELLOW}[3/4] Waiting for peers to complete (timeout: 5 minutes)...${NC}"

  local timeout=300
  local elapsed=0
  local all_done=false

  while [ $elapsed -lt $timeout ]; do
    # Check if all 4 peer containers have exited
    local alice_exit=$(docker inspect "$CONTAINER_PREFIX-peer-alice" --format='{{.State.ExitCode}}' 2>/dev/null || echo "-")
    local bob_exit=$(docker inspect "$CONTAINER_PREFIX-peer-bob" --format='{{.State.ExitCode}}' 2>/dev/null || echo "-")
    local charlie_exit=$(docker inspect "$CONTAINER_PREFIX-peer-charlie" --format='{{.State.ExitCode}}' 2>/dev/null || echo "-")
    local dave_exit=$(docker inspect "$CONTAINER_PREFIX-peer-dave" --format='{{.State.ExitCode}}' 2>/dev/null || echo "-")

    if [[ "$alice_exit" != "-" && "$bob_exit" != "-" && "$charlie_exit" != "-" && "$dave_exit" != "-" ]]; then
      all_done=true
      break
    fi

    sleep 5
    elapsed=$((elapsed + 5))
    echo "  [$((elapsed/60))m$((elapsed%60))s] Waiting... (Alice: $alice_exit, Bob: $bob_exit, Charlie: $charlie_exit, Dave: $dave_exit)"
  done

  if [ "$all_done" = false ]; then
    echo -e "${YELLOW}[⏱️  ] Timeout reached, collecting results...${NC}"
  fi

  # Collect exit codes
  echo -e "${YELLOW}[4/4] Collecting results...${NC}"

  local alice_exit=$(docker inspect "$CONTAINER_PREFIX-peer-alice" --format='{{.State.ExitCode}}' 2>/dev/null || echo "N/A")
  local bob_exit=$(docker inspect "$CONTAINER_PREFIX-peer-bob" --format='{{.State.ExitCode}}' 2>/dev/null || echo "N/A")
  local charlie_exit=$(docker inspect "$CONTAINER_PREFIX-peer-charlie" --format='{{.State.ExitCode}}' 2>/dev/null || echo "N/A")
  local dave_exit=$(docker inspect "$CONTAINER_PREFIX-peer-dave" --format='{{.State.ExitCode}}' 2>/dev/null || echo "N/A")

  # Display results
  echo ""
  echo -e "${CYAN}Exit Codes:${NC}"
  echo "  Alice:   $alice_exit"
  echo "  Bob:     $bob_exit"
  echo "  Charlie: $charlie_exit"
  echo "  Dave:    $dave_exit"
  echo ""
  echo -e "Expected: $expected"
  echo ""

  # Collect logs
  echo -e "${CYAN}Collecting logs...${NC}"
  docker logs "$CONTAINER_PREFIX-peer-alice" > "nat-$nat_type-alice.log" 2>&1 || true
  docker logs "$CONTAINER_PREFIX-peer-bob" > "nat-$nat_type-bob.log" 2>&1 || true
  docker logs "$CONTAINER_PREFIX-peer-charlie" > "nat-$nat_type-charlie.log" 2>&1 || true
  docker logs "$CONTAINER_PREFIX-peer-dave" > "nat-$nat_type-dave.log" 2>&1 || true

  # Extract verification summary from logs
  echo -e "${CYAN}Verification Summary:${NC}"
  local test_actually_ran=false
  for peer in alice bob charlie dave; do
    local log_file="nat-$nat_type-$peer.log"
    if [ -f "$log_file" ] && [ -s "$log_file" ]; then
      test_actually_ran=true
      echo "  [$peer] $(grep -oP "(?<=Expected: )\d+|(?<=Received: )\d+|✅ ALL CHECKS PASSED|❌ VERIFICATION FAILED" "$log_file" | head -3 | tr '\n' ' ')"
    else
      echo "  [$peer] (no output - container may have failed to start)"
    fi
  done

  if [ "$test_actually_ran" = false ]; then
    echo ""
    echo -e "${RED}⚠️  WARNING: Test containers did NOT produce any output!${NC}"
    echo -e "${RED}    This suggests peers failed to start or network setup failed.${NC}"
    echo -e "${RED}    Check Docker daemon for network/port conflicts.${NC}"
  fi
  echo ""

  # Clean up
  docker compose -f "$COMPOSE_FILE" down -v 2>/dev/null || true

  # Write to results file
  {
    echo "$nat_name:"
    echo "  Alice:   $alice_exit"
    echo "  Bob:     $bob_exit"
    echo "  Charlie: $charlie_exit"
    echo "  Dave:    $dave_exit"
    echo "  Expected: $expected"
    echo ""
  } >> "$RESULTS_FILE"
}

# Run all tests
for nat_type in "${!NAT_TYPES[@]}"; do
  run_nat_test "$nat_type" || true

  # Extra aggressive cleanup between tests to avoid routing/iptables conflicts
  sleep 2
  docker system prune -af --volumes 2>/dev/null || true
done

# Final summary
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}FINAL SUMMARY${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
cat "$RESULTS_FILE"
echo ""
echo -e "${CYAN}Log files saved:${NC}"
echo "  nat-fullcone-*.log"
echo "  nat-addressrestricted-*.log"
echo "  nat-portrestricted-*.log"
echo "  nat-symmetric-*.log"
echo ""
echo -e "${CYAN}Summary file:${NC}"
echo "  $RESULTS_FILE"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "Test suite complete!"
echo ""
