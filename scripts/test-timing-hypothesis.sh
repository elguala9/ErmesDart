#!/bin/bash
set -e

# Timing Hypothesis Test
# ======================
# Tests whether Address-Restricted and Port-Restricted NAT failures are
# due to timing issues (race conditions) rather than fundamental NAT limitations.
#
# Compares:
# - Standard config (5s post_connection_delay, 120s keepalive)
# - Slow config (20s post_connection_delay, 180s keepalive)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS_FILE="$REPO_ROOT/timing-hypothesis-results.txt"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

: > "$RESULTS_FILE"

echo -e "${CYAN}╔═════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  NAT TIMING HYPOTHESIS TEST                                 ║${NC}"
echo -e "${CYAN}║  Does increasing post_connection_delay_seconds fix failures? ║${NC}"
echo -e "${CYAN}╚═════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Hypothesis: Address-Restricted and Port-Restricted NAT failures are"
echo "caused by timing races, not fundamental NAT limitations."
echo ""
echo "Test Plan:"
echo "1. Test Address-Restricted with STANDARD timing (5s delay)"
echo "2. Test Address-Restricted with SLOW timing (20s delay)"
echo "3. Test Port-Restricted with STANDARD timing (5s delay)"
echo "4. Test Port-Restricted with SLOW timing (20s delay)"
echo ""

run_test() {
  local nat_type=$1
  local variant=$2
  local compose_file=$3
  local expected=$4

  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Testing: $nat_type ($variant)${NC}"
  echo -e "${BLUE}Compose: $compose_file${NC}"
  echo -e "${BLUE}Expected: $expected${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  cd "$REPO_ROOT"

  # Clean up
  echo -e "${YELLOW}[1/4] Cleaning up previous containers...${NC}"
  docker compose -f "$compose_file" down -v 2>/dev/null || true
  sleep 2

  # Build and start
  echo -e "${YELLOW}[2/4] Building and starting containers...${NC}"
  docker compose -f "$compose_file" up --build -d 2>&1 | tail -5

  # Wait for completion (with timeout)
  echo -e "${YELLOW}[3/4] Waiting for peers to complete (max 10 minutes)...${NC}"

  local timeout=600
  local elapsed=0
  local container_prefix=$(echo "$compose_file" | grep -oP 'ermes-nat-\K[^-]+(?=-)')

  if [[ "$variant" == "slow" ]]; then
    container_prefix="${container_prefix}-slow"
  fi

  while [ $elapsed -lt $timeout ]; do
    local alice=$(docker inspect "ermes-nat-${container_prefix}-peer-alice" --format='{{.State.ExitCode}}' 2>/dev/null || echo "-")
    local bob=$(docker inspect "ermes-nat-${container_prefix}-peer-bob" --format='{{.State.ExitCode}}' 2>/dev/null || echo "-")
    local charlie=$(docker inspect "ermes-nat-${container_prefix}-peer-charlie" --format='{{.State.ExitCode}}' 2>/dev/null || echo "-")
    local dave=$(docker inspect "ermes-nat-${container_prefix}-peer-dave" --format='{{.State.ExitCode}}' 2>/dev/null || echo "-")

    if [[ "$alice" != "-" && "$bob" != "-" && "$charlie" != "-" && "$dave" != "-" ]]; then
      break
    fi

    sleep 10
    elapsed=$((elapsed + 10))
    printf "  [%2dm%2ds] Alice:%s Bob:%s Charlie:%s Dave:%s\r" \
      $((elapsed/60)) $((elapsed%60)) "$alice" "$bob" "$charlie" "$dave"
  done

  echo ""
  echo -e "${YELLOW}[4/4] Collecting exit codes...${NC}"
  echo ""

  local alice=$(docker inspect "ermes-nat-${container_prefix}-peer-alice" --format='{{.State.ExitCode}}' 2>/dev/null || echo "N/A")
  local bob=$(docker inspect "ermes-nat-${container_prefix}-peer-bob" --format='{{.State.ExitCode}}' 2>/dev/null || echo "N/A")
  local charlie=$(docker inspect "ermes-nat-${container_prefix}-peer-charlie" --format='{{.State.ExitCode}}' 2>/dev/null || echo "N/A")
  local dave=$(docker inspect "ermes-nat-${container_prefix}-peer-dave" --format='{{.State.ExitCode}}' 2>/dev/null || echo "N/A")

  # Count successes
  local success_count=0
  [[ "$alice" == "0" ]] && success_count=$((success_count + 1))
  [[ "$bob" == "0" ]] && success_count=$((success_count + 1))
  [[ "$charlie" == "0" ]] && success_count=$((success_count + 1))
  [[ "$dave" == "0" ]] && success_count=$((success_count + 1))

  # Display results
  if [ "$success_count" -eq 4 ]; then
    echo -e "${GREEN}✅ ALL PEERS PASSED (4/4)${NC}"
  elif [ "$success_count" -ge 2 ]; then
    echo -e "${YELLOW}⚠️  PARTIAL SUCCESS ($success_count/4)${NC}"
  else
    echo -e "${RED}❌ MOSTLY FAILED ($success_count/4)${NC}"
  fi

  echo ""
  echo "Exit Codes:"
  echo "  Alice:   $alice"
  echo "  Bob:     $bob"
  echo "  Charlie: $charlie"
  echo "  Dave:    $dave"
  echo ""

  # Collect logs for diagnostics
  docker logs "ermes-nat-${container_prefix}-peer-alice" > "nat-${container_prefix}-alice.log" 2>&1 || true
  docker logs "ermes-nat-${container_prefix}-peer-bob" > "nat-${container_prefix}-bob.log" 2>&1 || true

  # Extract key info from logs
  echo "Summary from logs:"
  for peer in alice bob; do
    local log_file="nat-${container_prefix}-${peer}.log"
    if [ -f "$log_file" ]; then
      local expected_msgs=$(grep "Expected:" "$log_file" | head -1 | grep -oP '(?<=Expected: )\d+' || echo "?")
      local received_msgs=$(grep "Received:" "$log_file" | head -1 | grep -oP '(?<=Received: )\d+' || echo "?")
      echo "  [$peer] Expected: $expected_msgs, Received: $received_msgs"
    fi
  done
  echo ""

  # Write to results file
  {
    echo "$nat_type ($variant):"
    echo "  Alice:   $alice"
    echo "  Bob:     $bob"
    echo "  Charlie: $charlie"
    echo "  Dave:    $dave"
    echo "  Success: $success_count/4"
    echo ""
  } >> "$RESULTS_FILE"

  # Clean up
  docker compose -f "$compose_file" down -v 2>/dev/null || true
  sleep 2
}

# Run tests
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}PHASE 1: Address-Restricted NAT${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

run_test "Address-Restricted" "STANDARD (5s delay)" \
  "docker-compose-nat-addressrestricted.yml" \
  "⚠️  Mixed (timing race expected)"

echo ""
sleep 5
echo ""

run_test "Address-Restricted" "SLOW (20s delay)" \
  "docker-compose-nat-addressrestricted-slow.yml" \
  "✅ Improved (race condition avoided)"

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}PHASE 2: Port-Restricted NAT${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

run_test "Port-Restricted" "STANDARD (5s delay)" \
  "docker-compose-nat-portrestricted.yml" \
  "❌ Mostly fails (port mismatch expected)"

echo ""
sleep 5
echo ""

run_test "Port-Restricted" "SLOW (20s delay)" \
  "docker-compose-nat-portrestricted-slow.yml" \
  "⚠️  Improved (may still fail due to port filtering)"

# Final summary
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}HYPOTHESIS TEST RESULTS${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

cat "$RESULTS_FILE"

echo ""
echo -e "${CYAN}Analysis:${NC}"
echo ""
echo "Compare the 'Standard' vs 'Slow' results:"
echo ""
echo "IF slow config shows IMPROVEMENT → Problem is TIMING RACE CONDITION"
echo "   Solution: Increase post_connection_delay_seconds in config"
echo ""
echo "IF slow config shows NO CHANGE → Problem is FUNDAMENTAL NAT LIMITATION"
echo "   Solution: Implement TURN fallback or other workaround"
echo ""

echo "Summary file: $RESULTS_FILE"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
