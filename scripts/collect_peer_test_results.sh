#!/bin/bash
# Collect Docker peer test results and create summary report

set -e

RESULTS_DIR="test_results"
SUMMARY_FILE="test_results_summary.json"

echo "📊 Collecting peer test results..."

if [ ! -d "$RESULTS_DIR" ]; then
    echo "❌ No test results directory found at $RESULTS_DIR"
    exit 1
fi

# Count results
RESULT_COUNT=$(find "$RESULTS_DIR" -name "*_result.json" -type f | wc -l)

if [ "$RESULT_COUNT" -eq 0 ]; then
    echo "❌ No peer test results found in $RESULTS_DIR"
    exit 1
fi

echo "✅ Found $RESULT_COUNT peer results"

# Build summary
{
    echo "{"
    echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"total_peers\": $RESULT_COUNT,"
    echo "  \"results\": ["

    first=true
    total_success=0
    total_expected=0
    total_received=0

    for result_file in "$RESULTS_DIR"/*_result.json; do
        if [ -f "$result_file" ]; then
            if [ "$first" = false ]; then
                echo ","
            fi
            cat "$result_file"
            first=false

            # Parse results for summary stats
            success=$(jq -r '.success' "$result_file")
            expected=$(jq -r '.expected_messages' "$result_file")
            received=$(jq -r '.received_messages' "$result_file")

            if [ "$success" = "true" ]; then
                ((total_success++))
            fi
            total_expected=$((total_expected + expected))
            total_received=$((total_received + received))
        fi
    done

    echo ""
    echo "  ],"
    echo "  \"summary\": {"
    echo "    \"peers_passed\": $total_success,$RESULT_COUNT"
    echo "    \"total_peers\": $RESULT_COUNT,"
    echo "    \"success_rate\": \"$total_success/$RESULT_COUNT\","
    echo "    \"total_messages_expected\": $total_expected,"
    echo "    \"total_messages_received\": $total_received,"
    echo "    \"all_passed\": $([ "$total_success" -eq "$RESULT_COUNT" ] && echo 'true' || echo 'false')"
    echo "  }"
    echo "}"
} > "$SUMMARY_FILE"

echo ""
echo "✅ Test summary saved to: $SUMMARY_FILE"
echo ""
echo "📄 Summary:"
cat "$SUMMARY_FILE" | jq '.'

# Exit with success only if all peers passed
if jq -e '.summary.all_passed' "$SUMMARY_FILE" > /dev/null; then
    echo ""
    echo "🎉 ALL PEER TESTS PASSED!"
    exit 0
else
    echo ""
    echo "❌ SOME PEER TESTS FAILED"
    exit 1
fi
