# ermes_test_with_mock

Test utilities that explicitly *require* mocks/fakes.

## Why this package exists

The main test suite in `ermes_test` follows the project rule of **no mocks** — tests use real implementations against the interfaces in `iermes`. A few scenarios cannot be exercised without test doubles (e.g. simulating network errors, controlling time, or asserting that a callback was invoked exactly once). Those tests live here, isolated from the rest of the suite.

## Scope

Only tests that genuinely require a mock belong here. New tests should default to `ermes_test`; this package is the exception, not the rule.

## Running

Tests in this package run together with the rest of the workspace via `melos test`.
