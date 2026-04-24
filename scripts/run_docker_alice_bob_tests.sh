#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Starting OrcErmes Docker Alice-Bob Integration Tests ==="
echo "Project root: $PROJECT_ROOT"

cd "$PROJECT_ROOT"

# Validate docker-compose file
echo "Validating docker-compose configuration..."
docker compose -f docker-compose-alice-bob.yml config > /dev/null || exit 1

# Build and start all services
echo "Building Docker images and starting services..."
docker compose -f docker-compose-alice-bob.yml up --build

# Wait a moment for containers to finish writing results
sleep 2

# Extract results from volume
echo ""
echo "=== Test Results ==="
echo ""

if docker run --rm -v "$(docker compose -f docker-compose-alice-bob.yml volume ls 2>/dev/null | grep test-output | awk '{print $2}' || echo 'ermes_test_docker_test-output'):/data" alpine test -f /data/alice_result.json; then
  echo "Alice Results:"
  docker run --rm -v "ermes_test_docker_test-output:/data" alpine cat /data/alice_result.json | jq . || echo "Could not parse alice_result.json"
else
  echo "Alice results not found"
fi

if docker run --rm -v "ermes_test_docker_test-output:/data" alpine test -f /data/bob_result.json; then
  echo ""
  echo "Bob Results:"
  docker run --rm -v "ermes_test_docker_test-output:/data" alpine cat /data/bob_result.json | jq . || echo "Could not parse bob_result.json"
else
  echo "Bob results not found"
fi

# Check exit codes
echo ""
echo "=== Container Exit Codes ==="
ALICE_EXIT=$(docker inspect ermes-ab-alice --format='{{.State.ExitCode}}' 2>/dev/null || echo "unknown")
BOB_EXIT=$(docker inspect ermes-ab-bob --format='{{.State.ExitCode}}' 2>/dev/null || echo "unknown")

echo "Alice: $ALICE_EXIT (0 = success)"
echo "Bob: $BOB_EXIT (0 = success)"

if [ "$ALICE_EXIT" = "0" ] && [ "$BOB_EXIT" = "0" ]; then
  echo ""
  echo "✅ All tests passed!"
  EXIT_CODE=0
else
  echo ""
  echo "❌ Some tests failed"
  EXIT_CODE=1
fi

# Optional cleanup
echo ""
read -p "Clean up containers and volumes? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Cleaning up..."
  docker compose -f docker-compose-alice-bob.yml down -v
fi

exit $EXIT_CODE
