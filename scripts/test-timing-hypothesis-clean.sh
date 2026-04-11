#!/bin/bash
set -e

# Timing Hypothesis Test - CLEAN VERSION
# Avec nettoyage agressif entre les tests

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
echo -e "${CYAN}║  NAT TIMING HYPOTHESIS TEST (Clean)                        ║${NC}"
echo -e "${CYAN}║  Does increasing post_connection_delay_seconds fix failures?║${NC}"
echo -e "${CYAN}╚═════════════════════════════════════════════════════════════╝${NC}"
echo ""

run_test() {
  local nat_type=$1
  local variant=$2
  local compose_file=$3
  local expected=$4

  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}Testing: $nat_type ($variant)${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  cd "$REPO_ROOT"

  # AGGRESSIVE cleanup
  echo -e "${YELLOW}[1/4] Aggressive cleanup...${NC}"
  docker ps -aq | xargs -r docker rm -f 2>/dev/null || true
  docker network ls --filter "name=ermes" -q | xargs -r docker network rm 2>/dev/null || true
  sleep 3

  # Build and start
  echo -e "${YELLOW}[2/4] Building and starting (this takes a few minutes)...${NC}"
  docker compose -f "$compose_file" up --build --detach 2>&1 | grep -E "Starting|Started|built" || true

  # Wait for completion
  echo -e "${YELLOW}[3/4] Waiting for peers to complete...${NC}"
  local timeout=600
  local elapsed=0

  # Extract prefix from compose file name
  local prefix=$(basename "$compose_file" .yml | sed 's/docker-compose-/ermes-/')

  while [ $elapsed -lt $timeout ]; do
    # Get all peer containers for this prefix
    local alice=$(docker ps -a --filter "name=${prefix}-peer-alice" --format '{{.Names}}' 2>/dev/null | head -1)

    if [ -z "$alice" ]; then
      sleep 5
      elapsed=$((elapsed + 5))
      printf "  [%2dm%2ds] Waiting for containers to start...\r" $((elapsed/60)) $((elapsed%60))
      continue
    fi

    local alice_exit=$(docker inspect "$alice" --format='{{.State.ExitCode}}' 2>/dev/null || echo "-")
    local bob=$(docker ps -a --filter "name=${prefix}-peer-bob" --format '{{.Names}}' 2>/dev/null | head -1)
    local bob_exit=$(docker inspect "$bob" --format='{{.State.ExitCode}}' 2>/dev/null || echo "-")
    local charlie=$(docker ps -a --filter "name=${prefix}-peer-charlie" --format '{{.Names}}' 2>/dev/null | head -1)
    local charlie_exit=$(docker inspect "$charlie" --format='{{.State.ExitCode}}' 2>/dev/null || echo "-")
    local dave=$(docker ps -a --filter "name=${prefix}-peer-dave" --format '{{.Names}}' 2>/dev/null | head -1)
    local dave_exit=$(docker inspect "$dave" --format='{{.State.ExitCode}}' 2>/dev/null || echo "-")

    if [[ "$alice_exit" != "-" && "$bob_exit" != "-" && "$charlie_exit" != "-" && "$dave_exit" != "-" ]]; then
      # All have exited
      break
    fi

    sleep 10
    elapsed=$((elapsed + 10))
    printf "  [%2dm%2ds] A:%s B:%s C:%s D:%s\r" $((elapsed/60)) $((elapsed%60)) "$alice_exit" "$bob_exit" "$charlie_exit" "$dave_exit"
  done

  echo ""
  echo -e "${YELLOW}[4/4] Collecting results...${NC}"
  echo ""

  # Get the containers
  local alice=$(docker ps -a --filter "name=${prefix}-peer-alice" --format '{{.Names}}' 2>/dev/null | head -1)
  local bob=$(docker ps -a --filter "name=${prefix}-peer-bob" --format '{{.Names}}' 2>/dev/null | head -1)
  local charlie=$(docker ps -a --filter "name=${prefix}-peer-charlie" --format '{{.Names}}' 2>/dev/null | head -1)
  local dave=$(docker ps -a --filter "name=${prefix}-peer-dave" --format '{{.Names}}' 2>/dev/null | head -1)

  local alice_exit=$(docker inspect "$alice" --format='{{.State.ExitCode}}' 2>/dev/null || echo "N/A")
  local bob_exit=$(docker inspect "$bob" --format='{{.State.ExitCode}}' 2>/dev/null || echo "N/A")
  local charlie_exit=$(docker inspect "$charlie" --format='{{.State.ExitCode}}' 2>/dev/null || echo "N/A")
  local dave_exit=$(docker inspect "$dave" --format='{{.State.ExitCode}}' 2>/dev/null || echo "N/A")

  # Count successes
  local success_count=0
  [[ "$alice_exit" == "0" ]] && success_count=$((success_count + 1))
  [[ "$bob_exit" == "0" ]] && success_count=$((success_count + 1))
  [[ "$charlie_exit" == "0" ]] && success_count=$((success_count + 1))
  [[ "$dave_exit" == "0" ]] && success_count=$((success_count + 1))

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
  echo "  Alice:   $alice_exit"
  echo "  Bob:     $bob_exit"
  echo "  Charlie: $charlie_exit"
  echo "  Dave:    $dave_exit"
  echo ""

  # Write to results file
  {
    echo "$nat_type ($variant):"
    echo "  Alice:   $alice_exit"
    echo "  Bob:     $bob_exit"
    echo "  Charlie: $charlie_exit"
    echo "  Dave:    $dave_exit"
    echo "  Success: $success_count/4"
    echo ""
  } >> "$RESULTS_FILE"

  # Log extraction
  if [ -n "$alice" ]; then
    docker logs "$alice" > "nat-${prefix}-alice.log" 2>&1 || true
  fi
  if [ -n "$bob" ]; then
    docker logs "$bob" > "nat-${prefix}-bob.log" 2>&1 || true
  fi

  echo "Logs saved to nat-${prefix}-*.log"
  echo ""
}

# Run tests
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}PHASE 1: Address-Restricted NAT${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

run_test "Address-Restricted" "STANDARD (5s delay)" \
  "docker-compose-nat-addressrestricted.yml" \
  "⚠️  Mixed"

sleep 10

run_test "Address-Restricted" "SLOW (20s delay)" \
  "docker-compose-nat-addressrestricted-slow.yml" \
  "✅ Improved?"

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}PHASE 2: Port-Restricted NAT${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

run_test "Port-Restricted" "STANDARD (5s delay)" \
  "docker-compose-nat-portrestricted.yml" \
  "❌ Mostly fails"

sleep 10

run_test "Port-Restricted" "SLOW (20s delay)" \
  "docker-compose-nat-portrestricted-slow.yml" \
  "⚠️  Improved?"

# Final summary
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}HYPOTHESIS TEST RESULTS${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

cat "$RESULTS_FILE"

echo ""
echo -e "${CYAN}ANALYSIS:${NC}"
echo ""
echo "Address-Restricted Improvement:"
ADDR_STD=$(grep -A 4 "Address-Restricted (STANDARD" "$RESULTS_FILE" | grep "Success:" | grep -oP '\d+(?=/4)' | head -1)
ADDR_SLOW=$(grep -A 4 "Address-Restricted (SLOW" "$RESULTS_FILE" | grep "Success:" | grep -oP '\d+(?=/4)' | head -1)
echo "  Standard: $ADDR_STD/4"
echo "  Slow:     $ADDR_SLOW/4"
if [ "$ADDR_SLOW" -gt "$ADDR_STD" ]; then
  echo "  ✅ IMPROVEMENT! (+$((ADDR_SLOW - ADDR_STD)) peers)"
else
  echo "  ❌ NO CHANGE - Timing not the issue"
fi

echo ""
echo "Port-Restricted Improvement:"
PORT_STD=$(grep -A 4 "Port-Restricted (STANDARD" "$RESULTS_FILE" | grep "Success:" | grep -oP '\d+(?=/4)' | head -1)
PORT_SLOW=$(grep -A 4 "Port-Restricted (SLOW" "$RESULTS_FILE" | grep "Success:" | grep -oP '\d+(?=/4)' | head -1)
echo "  Standard: $PORT_STD/4"
echo "  Slow:     $PORT_SLOW/4"
if [ "$PORT_SLOW" -gt "$PORT_STD" ]; then
  echo "  ✅ IMPROVEMENT! (+$((PORT_SLOW - PORT_STD)) peers)"
else
  echo "  ❌ NO CHANGE - Timing not the issue"
fi

echo ""
echo "Results file: $RESULTS_FILE"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
