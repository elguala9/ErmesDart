# ErmesDart Monorepo - Setup Guide

## Quick Start

### Prerequisites
- Dart SDK >=3.2.0
- Git

### Initial Setup

1. **Install Melos** (if not already installed):
   ```bash
   dart pub global activate melos
   ```

2. **Bootstrap the monorepo** (from the root directory):
   
   On Windows:
   ```cmd
   scripts\bootstrap.bat
   ```
   
   On Unix/Linux/macOS:
   ```bash
   bash scripts/bootstrap.sh
   ```

   Or manually:
   ```bash
   melos bootstrap
   ```

## Project Structure

```
ErmesDart/
├── .github/
│   └── workflows/
│       └── ci.yml                 # GitHub Actions CI workflow
├── .vscode/                       # VS Code configuration
│   ├── extensions.json
│   ├── launch.json
│   └── settings.json
├── apps/                          # Applications
│   └── cli/                       # CLI application
│       ├── bin/
│       │   └── main.dart
│       ├── pubspec.yaml
│       └── README.md
├── packages/                      # Shared packages
│   ├── common/                    # Common utilities
│   │   ├── lib/
│   │   │   ├── ermes_common.dart
│   │   │   └── src/
│   │   │       ├── extensions/
│   │   │       │   ├── extensions.dart
│   │   │       │   └── string_extensions.dart
│   │   │       └── utils/
│   │   │           └── string_utils.dart
│   │   ├── pubspec.yaml
│   │   └── README.md
│   └── core/                      # Core domain logic
│       ├── lib/
│       │   ├── ermes_core.dart
│       │   └── src/
│       │       ├── exceptions/
│       │       │   ├── exceptions.dart
│       │       │   └── ermes_exception.dart
│       │       └── models/
│       │           ├── models.dart
│       │           └── example_model.dart
│       ├── test/
│       │   └── example_model_test.dart
│       ├── pubspec.yaml
│       └── README.md
├── scripts/                       # Utility scripts
│   ├── bootstrap.bat              # Windows bootstrap script
│   └── bootstrap.sh               # Unix bootstrap script
├── .gitignore
├── analysis_options.yaml          # Dart analyzer configuration
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── melos.yaml                     # Melos configuration
└── README.md

```

## Available Commands

### Melos Commands

All these commands should be run from the root directory:

```bash
# Bootstrap the monorepo (install dependencies, link packages)
melos bootstrap

# Analyze all packages
melos run analyze

# Format all code
melos run format

# Check formatting without modifying files
melos run format:check

# Run tests in all packages
melos run test

# Get dependencies for all packages
melos run get

# Clean all packages
melos run clean

# Run build_runner (for packages that use it)
melos run build
```

### Working with Individual Packages

```bash
# Navigate to a package
cd packages/core

# Run package-specific commands
dart test
dart analyze
dart format .
```

### CLI Application

```bash
# Run the CLI directly
cd apps/cli
dart run bin/main.dart --help

# Install globally
dart pub global activate --source path apps/cli

# Run globally (after installation)
ermes --help
```

## Development Workflow

1. **Create a new branch**:
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make your changes** in the appropriate package(s)

3. **Run tests and linting**:
   ```bash
   melos run test
   melos run analyze
   ```

4. **Format your code**:
   ```bash
   melos run format
   ```

5. **Commit and push**:
   ```bash
   git add .
   git commit -m "feat: add my feature"
   git push origin feature/my-feature
   ```

## Creating New Packages

### Library Package

```bash
# Create package directory
mkdir packages/my_package
cd packages/my_package

# Initialize with pubspec.yaml
cat > pubspec.yaml << EOF
name: ermes_my_package
description: Description of my package
version: 0.1.0
publish_to: none

environment:
  sdk: ">=3.2.0 <4.0.0"

dependencies:
  # Add dependencies

dev_dependencies:
  lints: ^3.0.0
  test: ^1.24.0
EOF

# Create lib structure
mkdir -p lib/src
touch lib/ermes_my_package.dart

# Run bootstrap to link
cd ../..
melos bootstrap
```

### Application Package

```bash
# Create app directory
mkdir apps/my_app
cd apps/my_app

# Initialize with pubspec.yaml
# Add dependencies to other packages using path:
#   dependencies:
#     ermes_core:
#       path: ../../packages/core

# Create bin/main.dart
mkdir bin
touch bin/main.dart

# Run bootstrap
cd ../..
melos bootstrap
```

## Package Dependencies

Packages can depend on each other. Use path dependencies in `pubspec.yaml`:

```yaml
dependencies:
  ermes_core:
    path: ../../packages/core
  ermes_common:
    path: ../../packages/common
```

Melos automatically manages these during `melos bootstrap`.

## IDE Support

### VS Code

The `.vscode` directory contains recommended settings:
- Auto-formatting on save
- Dart analysis
- Recommended extensions

Recommended extensions will be suggested when you open the project.

### IntelliJ IDEA / Android Studio

1. Open the project
2. Dart SDK should be detected automatically
3. Run `melos bootstrap` from the terminal
4. IDE will index all packages

## CI/CD

GitHub Actions workflow (`.github/workflows/ci.yml`) runs on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

The workflow:
1. Runs analysis on all packages
2. Checks code formatting
3. Runs tests on multiple OS (Linux, Windows, macOS) and Dart versions
4. Generates code coverage

## Troubleshooting

### Melos not found
```bash
dart pub global activate melos
```

### Packages not linking
```bash
melos clean
melos bootstrap
```

### IDE not recognizing packages
1. Run `melos bootstrap`
2. Restart your IDE
3. Invalidate caches if needed (IntelliJ)

### Test failures
```bash
# Run tests with verbose output
melos run test --no-select
```

## Next Steps

1. **Review the example packages** in `packages/core` and `packages/common`
2. **Try the CLI app** in `apps/cli`
3. **Create your own packages** following the structure
4. **Add tests** for new functionality
5. **Update documentation** as you add features

## Resources

- [Melos Documentation](https://melos.invertase.dev/)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Conventional Commits](https://www.conventionalcommits.org/)

## Support

For questions or issues:
- Open an issue on GitHub
- Check the CONTRIBUTING.md file
- Review existing documentation
