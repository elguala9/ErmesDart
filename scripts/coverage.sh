#!/bin/bash
# Script to generate code coverage report locally

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "📊 ErmesDart Code Coverage Generator"
echo ""

# Generate coverage
echo "🧪 Running tests with coverage instrumentation..."
dart test packages/ermes_test/test/ --coverage=coverage

if [ $? -eq 0 ]; then
    echo ""
    echo "📝 Converting to LCOV format..."
    dart pub global activate coverage
    dart pub global run coverage:format_coverage --in=coverage --out=coverage/lcov.info --lcov --report-on=packages/ermes_core/lib,packages/ermes_signaling/lib,packages/ermes_cipher/lib

    echo "✅ Coverage report generated at coverage/lcov.info"
    echo ""

    # Check if genhtml is available and generate HTML
    if command -v genhtml &> /dev/null; then
        echo "📈 Generating HTML report..."
        genhtml coverage/lcov.info -o coverage_html
        echo "✅ HTML report generated in coverage_html/"
        echo ""
        echo "🔗 View report:"
        echo "   open coverage_html/index.html"
    else
        echo "📝 To view as HTML, install genhtml:"
        echo "   dart pub global activate coverage"
        echo "   genhtml coverage/lcov.info -o coverage_html"
    fi
else
    echo ""
    echo "❌ Coverage generation failed"
    exit 1
fi
