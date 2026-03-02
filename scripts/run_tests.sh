#!/bin/bash
# Script to run tests with automatic Docker Compose setup for Ganache

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_COMPOSE_FILE="$PROJECT_DIR/docker-compose-evm.yml"

echo "🧪 Testing ErmesDart with optional Ganache support..."
echo ""

# Check if Docker is available
if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
    echo "✅ Docker is available"

    # Check if docker daemon is running
    if docker ps &> /dev/null; then
        echo "✅ Docker daemon is running"

        # Try to start Ganache
        if [ -f "$DOCKER_COMPOSE_FILE" ]; then
            echo "🚀 Starting Ganache from docker-compose..."
            docker-compose -f "$DOCKER_COMPOSE_FILE" up -d

            # Wait for Ganache to be ready
            echo "⏳ Waiting for Ganache to be ready..."
            for i in {1..30}; do
                if curl -s -X POST http://localhost:9545 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"web3_clientVersion","id":1}' > /dev/null 2>&1; then
                    echo "✅ Ganache is ready!"
                    break
                fi
                if [ $i -eq 30 ]; then
                    echo "⚠️  Ganache not responding, continuing with skipped tests..."
                fi
                sleep 1
            done
        fi
    else
        echo "⚠️  Docker daemon is not running, continuing with skipped Ganache tests..."
    fi
else
    echo "⚠️  Docker not available, ErmesSignalingServer tests will be skipped"
fi

echo ""
echo "Running tests..."
cd "$PROJECT_DIR"
dart test packages/ermes_test/test/

# Optional: Stop Ganache after tests
if command -v docker-compose &> /dev/null && [ -f "$DOCKER_COMPOSE_FILE" ]; then
    echo ""
    echo "🛑 Stopping Ganache..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" down
fi
