# Contributing to ErmesDart

Thank you for your interest in contributing to ErmesDart! This document provides guidelines and instructions for contributing.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/yourusername/ErmesDart.git
   cd ErmesDart
   ```
3. **Bootstrap the monorepo**:
   ```bash
   # On Windows
   scripts\bootstrap.bat
   
   # On Unix/Linux/macOS
   bash scripts/bootstrap.sh
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

- Write tests for new features and bug fixes
- Ensure all tests pass before submitting a PR
- Aim for high test coverage
- Run tests with: `melos run test`

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

When creating or modifying packages:

```
package_name/
├── lib/
│   ├── package_name.dart          # Main library file
│   └── src/                       # Implementation
│       ├── models/
│       ├── services/
│       └── utils/
├── test/                          # Tests
├── pubspec.yaml                   # Dependencies
└── README.md                      # Package documentation
```

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
