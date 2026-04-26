# Code Coverage Configuration

This project uses **code coverage** to track how much of the codebase is tested by the test suite.

## Generating Coverage Reports

### Using Melos (Recommended)

```bash
# Generate coverage data and LCOV file
melos run coverage

# Show coverage summary (percentages per file)
melos run coverage:report:summary

# Show detailed report with untested line numbers
melos run coverage:report
```

This will:
1. Run all tests in `packages/ermes_test/test/` with coverage instrumentation
2. Convert the coverage data to LCOV format
3. Generate `coverage/lcov.info` with the detailed report
4. Display a formatted coverage report with percentages

### Viewing the Report

After generating coverage, open the HTML report:

**Linux/Mac:**
```bash
# Install if not present
dart pub global activate coverage

# Generate HTML from LCOV
genhtml coverage/lcov.info -o coverage_html
open coverage_html/index.html
```

**Windows:**
```powershell
dart pub global activate coverage
genhtml coverage/lcov.info -o coverage_html
start coverage_html/index.html
```

## Understanding the Coverage Report

After running `melos run coverage:report`, you'll see:

```
📈 OVERALL COVERAGE: 21.9% (348/1589 lines)
════════════════════════════════════════════════════

❌ 0.0%   [░░░░░░░░░░] packages/ermes_core/lib/src/orc_ermes.dart
   0/97 lines tested
   ❌ Untested lines: 11, 12, 15, 21, 33 ... and 92 more

✅ 100.0% [██████████] packages/ermes_core/lib/src/ermes_utility/hash_utils.dart
   6/6 lines tested
```

**Reading the Report:**
- **Icon**: ✅ (80%+), ⚠️ (50-80%), ❌ (<50%)
- **Percentage**: Coverage % for that file
- **Bar chart**: Visual representation (█ = covered, ░ = untested)
- **Ratio**: How many lines are covered vs total
- **Untested lines**: Line numbers that haven't been executed (with --untested flag)

**Summary Section:**
- Files grouped by coverage level
- Quick overview of testing health

## What's Measured

The coverage report tracks:
- **Line coverage**: % of source lines executed by tests
- **Branch coverage**: % of conditional branches executed (in HTML report)
- **Function coverage**: % of functions called

Packages included in coverage:
- `packages/ermes_core/lib/`
- `packages/ermes_signaling/lib/`
- `packages/ermes_cipher/lib/`

## CI/CD Integration

Coverage is automatically generated on every push/PR to `main` and `develop` branches:
- Runs in GitHub Actions after all tests pass
- Reports are uploaded to **Codecov** for historical tracking
- View coverage trends at: https://codecov.io/gh/parresia/ErmesDart

## Key Metrics

**Line Coverage** measures:
- How many lines of production code are executed during tests
- ✅ Target: 80%+ for critical paths
- ⚠️ Not a guarantee of quality (a line can be covered but incorrectly)

**Branch Coverage** measures:
- How many decision branches (`if/else`, loops) are tested
- ✅ More meaningful than line coverage alone

## Using Coverage Reports to Improve Tests

1. **Find untested files**:
   ```bash
   melos run coverage:report
   ```
   Look for files with 0% coverage marked with ❌

2. **See which lines aren't tested**:
   The "Untested lines" section shows exactly which line numbers need test coverage

3. **Prioritize by coverage level**:
   - Start with critical files (ermes_core, ermes_cipher)
   - Files marked ❌ (<50%) are highest priority
   - Files marked ⚠️ (50-80%) could use a few more tests

4. **Add tests systematically**:
   - Pick a file with low coverage
   - Add tests for the untested lines
   - Re-run `melos run coverage:report` to verify improvement

## Important Notes

⚠️ **100% coverage ≠ quality tests**
- Coverage shows *what* was tested, not *how well*
- A line can be executed but tested incorrectly
- Focus on meaningful test assertions, not coverage percentage
- Use coverage to *identify* gaps, not as an absolute metric

💡 **Remember**: The goal is **meaningful tests**, not just hitting 100%. A test that exercises a code path is valuable; a test that just touches a line without asserting anything is not.

## Troubleshooting

**lcov.info not found:**
```bash
dart pub global activate coverage
format_coverage --help
```

**HTML report not generating:**
```bash
dart pub global activate coverage
genhtml --version
```

**Coverage showing 0%:**
- Ensure tests are running: `melos run test`
- Check that `coverage/` directory exists
- Verify `dart test` was run with `--coverage` flag
