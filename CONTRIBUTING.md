# Contributing to ErmesDart

Thank you for your interest in contributing to ErmesDart! This document provides guidelines and instructions for contributing.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/yourusername/ErmesDart.git
   cd ErmesDart
   ```
3. **Bootstrap the monorepo** (Dart workspace + Melos):
   ```bash
   dart pub get        # resolves the workspace
   melos bootstrap     # links packages
   ```

## Development Workflow

### Making Changes

1. Create a new branch for your feature or bugfix:
   ```bash
   git checkout -b feature/my-new-feature
   ```

2. Make your changes in the appropriate package(s)

3. Run tests and linting:
   ```bash
   melos run test
   melos run analyze
   ```

4. Format your code:
   ```bash
   melos run format
   ```

5. Commit your changes:
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

### Commit Message Convention

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` - A new feature
- `fix:` - A bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

Examples:
```
feat(core): add new ExampleModel
fix(cli): correct argument parsing
docs: update README with new examples
```

### Creating Packages

When creating a new package in the monorepo:

1. Create the package directory in `packages/` or `apps/`
2. Initialize with appropriate `pubspec.yaml`
3. Follow the existing structure
4. Run `melos bootstrap` to link dependencies
5. Add appropriate tests
6. Update documentation

### Testing

- All tests live in `packages/ermes_test/` (mocks only in
  `ermes_test_with_mock`); implementation packages have no `test/` directory.
- Write tests against **interfaces**, as top-level callable `void testXxx()`
  functions, using **real implementations** (no mocks). Cover success and
  error cases.
- Wire new test functions into `packages/ermes_test/test/concrete_implementations_test.dart`.
- Ensure all tests pass before submitting a PR; aim for high coverage.
- Run tests with: `dart test packages/ermes_test/test/` (or `melos run test`).

### Code Style

- Follow the Dart style guide
- Use the provided `analysis_options.yaml`
- Format code with `dart format`
- Fix analysis issues before submitting

### Pull Request Process

1. Update documentation if needed
2. Ensure all tests pass
3. Update the CHANGELOG if applicable
4. Push to your fork:
   ```bash
   git push origin feature/my-new-feature
   ```
5. Create a Pull Request on GitHub
6. Wait for review and address feedback

## Package Structure

This is the **standard layout** every package follows. Group implementation
files by **domain** (the cohesive feature they belong to), not by generic
technical layer — domain folders such as `key_exchange/`, `handshake/`,
`storage_implementation/` carry more meaning than a flat `models/services/`
split. Two folders are conventional across all packages: `factories/` and
`generated/`.

```
package_name/
├── lib/
│   ├── package_name.dart          # GENERATED barrel (index_generator) — never hand-edit
│   └── src/
│       ├── <domain>/              # cohesive feature groups, e.g.
│       │                          #   *_implementation/, key_exchange/,
│       │                          #   handshake/, stun/, caching_implementation/,
│       │                          #   storage_encryption/, validation/, logging/, models/
│       ├── factories/             # one factory per class, each taking an Input class
│       └── generated/             # generated DI registrations (singleton_manager)
├── index_generator.yaml           # barrel generation config
├── pubspec.yaml                   # dependencies
└── README.md                      # package documentation
```

Cross-cutting rules (see project `CLAUDE.md`):

- **Interfaces live only in `iermes/`.** Implementation packages reference
  interfaces, never the reverse, and contain no interface definitions.
- **Tests live only in `packages/ermes_test/`** (mocks only in
  `ermes_test_with_mock`). Implementation packages have **no** `test/` directory.
- **Barrels are generated.** Add or move a file under `lib/src`, then run
  `dart run index_generator` in the package — do not hand-edit `package_name.dart`.
- **One factory per class**, each accepting a dedicated `Input` class.
- Files ≤150 lines (excluding tests); functions ≤30 lines; no `dynamic`, no `as`.

## Code Review

All submissions require review. We use GitHub pull requests for this purpose:

- Be respectful and constructive
- Address review comments promptly
- Update your PR based on feedback
- Maintain a clean commit history

## Questions?

If you have questions:

- Open an issue on GitHub
- Check existing documentation
- Ask in discussions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
