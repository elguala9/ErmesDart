#!/bin/bash
set -e

# NAT Types Comprehensive Test Suite
# ===================================
# Tests all 4 NAT types with dual-router topology and saves results

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

echo "======================================================================"
echo "  ErmesDart P2P NAT Types Test Suite"
echo "  Dual-Router Topology: zone-a <-> router-a <-> public <-> router-b <-> zone-b"
echo "======================================================================"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Results output file
RESULTS_FILE="$REPO_ROOT/nat-test-results.txt"
RESULTS_LOG="$REPO_ROOT/nat-test-full.log"

{
  echo "ErmesDart NAT Test Results"
  echo "=========================="
  echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  echo "Topology: Dual-router (zone-a <-> router-a <-> public <-> router-b <-> zone-b)"
  echo ""
} > "$RESULTS_FILE"
: > "$RESULTS_LOG"

declare -A NAT_COMPOSE=(
  ["fullcone"]="docker-compose-nat-fullcone.yml"
  ["addressrestricted"]="docker-compose-nat-addressrestricted.yml"
  ["portrestricted"]="docker-compose-nat-portrestricted.yml"
  ["symmetric"]="docker-compose-nat-symmetric.yml"
)

declare -A NAT_NAMES=(
  ["fullcone"]="Full Cone NAT"
  ["addressrestricted"]="Address-Restricted Cone NAT"
  ["portrestricted"]="Port-Restricted Cone NAT"
  ["symmetric"]="Symmetric NAT"
)

declare -A EXPECTED=(
  ["fullcone"]="PASS (STUN works perfectly)"
  ["addressrestricted"]="PASS (NAT traversal with hole-punching)"
  ["portrestricted"]="PASS (NAT traversal with hole-punching)"
  ["symmetric"]="EXPECTED FAIL (STUN port randomized per destination)"
)

# Subnet prefixes for cross-bridge forwarding setup
declare -A SUBNET_PUBLIC=(
  ["fullcone"]="172.20.0" ["addressrestricted"]="172.21.0"
  ["portrestricted"]="172.22.0" ["symmetric"]="172.31.0"
)
declare -A SUBNET_ZONEA=(
  ["fullcone"]="172.20.10" ["addressrestricted"]="172.21.10"
  ["portrestricted"]="172.22.10" ["symmetric"]="172.31.10"
)
declare -A SUBNET_ZONEB=(
  ["fullcone"]="172.20.20" ["addressrestricted"]="172.21.20"
  ["portrestricted"]="172.22.20" ["symmetric"]="172.31.20"
)

# Track overall results
TOTAL_PASS=0
TOTAL_FAIL=0

run_nat_test() {
  local nat_type=$1
  local nat_name="${NAT_NAMES[$nat_type]}"
  local compose_file="$REPO_ROOT/${NAT_COMPOSE[$nat_type]}"
  local expected="${EXPECTED[$nat_type]}"
  local PUBLIC_PREFIX="${SUBNET_PUBLIC[$nat_type]}"
  local ZONEA_PREFIX="${SUBNET_ZONEA[$nat_type]}"
  local ZONEB_PREFIX="${SUBNET_ZONEB[$nat_type]}"

  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${CYAN}  Testing: $nat_name${NC}"
  echo -e "${CYAN}  Expected: $expected${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  if [ ! -f "$compose_file" ]; then
    echo -e "${RED}ERROR: Compose file not found: $compose_file${NC}"
    return 1
  fi

  # Cleanup
  echo -e "${YELLOW}[1/5] Cleaning up previous containers...${NC}"
  cd "$REPO_ROOT"
  docker compose -f "$compose_file" down -v 2>/dev/null || true
  sleep 2

  # Start
  echo -e "${YELLOW}[2/5] Building and starting containers...${NC}"
  docker compose -f "$compose_file" up --build -d 2>&1 | tee -a "$RESULTS_LOG"

  # Enable cross-bridge forwarding (Docker bridge isolation blocks inter-network routing)
  echo -e "${YELLOW}[2b/5] Enabling cross-bridge forwarding...${NC}"
  MSYS_NO_PATHCONV=1 docker run --rm --privileged --network host --pid host \
    -v "$REPO_ROOT/scripts/nat-network-setup.sh:/nat-setup.sh:ro" \
    -e PUBLIC_SUBNET_PREFIX="${PUBLIC_PREFIX}" \
    -e ZONEA_SUBNET_PREFIX="${ZONEA_PREFIX}" \
    -e ZONEB_SUBNET_PREFIX="${ZONEB_PREFIX}" \
    alpine:3.19 sh /nat-setup.sh 2>&1 | tee -a "$RESULTS_LOG"

  # Wait for peers to finish (timeout: 5 minutes)
  echo -e "${YELLOW}[3/5] Waiting for peers to complete (timeout: 5 min)...${NC}"
  local timeout=300
  local elapsed=0
  local all_done=false

  while [ $elapsed -lt $timeout ]; do
    local running=0
    for peer in alice bob charlie dave; do
      local container_name=$(docker compose -f "$compose_file" ps --format '{{.Name}}' 2>/dev/null | grep "peer-$peer" || true)
      if [ -n "$container_name" ]; then
        local status=$(docker inspect "$container_name" --format='{{.State.Status}}' 2>/dev/null || echo "unknown")
        if [ "$status" = "running" ]; then
          running=$((running + 1))
        fi
      fi
    done

    if [ $running -eq 0 ]; then
      all_done=true
      break
    fi

    sleep 5
    elapsed=$((elapsed + 5))
    echo "  [${elapsed}s] Still running: $running peers"
  done

  if [ "$all_done" = false ]; then
    echo -e "${YELLOW}  Timeout reached after ${timeout}s${NC}"
  fi

  # Collect results
  echo -e "${YELLOW}[4/5] Collecting results...${NC}"

  local pass=0
  local fail=0
  local peer_results=""

  for peer in alice bob charlie dave; do
    local container_name=$(docker compose -f "$compose_file" ps -a --format '{{.Name}}' 2>/dev/null | grep "peer-$peer" || true)
    if [ -z "$container_name" ]; then
      peer_results+="  $(echo $peer | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}'): CONTAINER NOT FOUND\n"
      fail=$((fail + 1))
      continue
    fi

    local exit_code=$(docker inspect "$container_name" --format='{{.State.ExitCode}}' 2>/dev/null || echo "N/A")
    local peer_name=$(echo $peer | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')

    # Save peer log
    docker logs "$container_name" > "$REPO_ROOT/nat-${nat_type}-${peer}.log" 2>&1 || true

    # Extract verification summary
    local received=$(grep "Received:" "$REPO_ROOT/nat-${nat_type}-${peer}.log" 2>/dev/null | grep -oP '\d+' | head -1 || echo "?")
    local expected_msgs=$(grep "Expected:" "$REPO_ROOT/nat-${nat_type}-${peer}.log" 2>/dev/null | grep -oP '\d+' | head -1 || echo "?")

    if [ "$exit_code" = "0" ]; then
      peer_results+="  $peer_name: PASS (exit=$exit_code, received=$received/$expected_msgs messages)\n"
      pass=$((pass + 1))
    else
      peer_results+="  $peer_name: FAIL (exit=$exit_code, received=$received/$expected_msgs messages)\n"
      fail=$((fail + 1))
    fi
  done

  # Check router logs
  for router in router-a router-b; do
    local container_name=$(docker compose -f "$compose_file" ps -a --format '{{.Name}}' 2>/dev/null | grep "$router" || true)
    if [ -n "$container_name" ]; then
      docker logs "$container_name" > "$REPO_ROOT/nat-${nat_type}-${router}.log" 2>&1 || true
    fi
  done

  # Display results
  echo ""
  echo -e "  ${CYAN}Peer Results:${NC}"
  echo -e "$peer_results"

  local test_status
  if [ $fail -eq 0 ]; then
    test_status="ALL PASSED ($pass/4)"
    echo -e "  ${GREEN}Result: $test_status${NC}"
    TOTAL_PASS=$((TOTAL_PASS + pass))
  else
    test_status="$pass PASSED, $fail FAILED (out of 4)"
    echo -e "  ${RED}Result: $test_status${NC}"
    TOTAL_PASS=$((TOTAL_PASS + pass))
    TOTAL_FAIL=$((TOTAL_FAIL + fail))
  fi

  # Write to results file
  {
    echo "[$nat_name]"
    echo -e "$peer_results"
    echo "  Result: $test_status"
    echo "  Expected: $expected"
    echo ""
  } >> "$RESULTS_FILE"

  # Cleanup
  echo -e "${YELLOW}[5/5] Cleaning up...${NC}"
  docker compose -f "$compose_file" down -v 2>/dev/null || true
}

# Run all 4 NAT types
for nat_type in fullcone addressrestricted portrestricted symmetric; do
  run_nat_test "$nat_type" || true
  sleep 2
done

# Final summary
{
  echo "=============================="
  echo "SUMMARY"
  echo "=============================="
  echo "Total peers passed: $TOTAL_PASS"
  echo "Total peers failed: $TOTAL_FAIL"
  echo "Total peers tested: $((TOTAL_PASS + TOTAL_FAIL))"
  echo ""
  echo "Generated at: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
} >> "$RESULTS_FILE"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  FINAL SUMMARY${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Passed: ${GREEN}$TOTAL_PASS${NC}  Failed: ${RED}$TOTAL_FAIL${NC}  Total: $((TOTAL_PASS + TOTAL_FAIL))"
echo ""
echo "  Results: $RESULTS_FILE"
echo "  Logs:    nat-<type>-<peer>.log"
echo ""
cat "$RESULTS_FILE"
