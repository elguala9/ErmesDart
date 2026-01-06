# ErmesDart Monorepo

A monorepo for the ErmesDart project using Melos for workspace management.

## Structure

```
ermes_dart/
├── packages/          # Shared Dart packages
│   ├── core/         # Core domain logic and models
│   ├── data/         # Data layer (repositories, data sources)
│   └── common/       # Common utilities and shared code
├── apps/             # Applications
│   ├── cli/          # Command-line interface
│   └── server/       # Server application
├── melos.yaml        # Melos configuration
└── README.md         # This file
```

## Prerequisites

- Dart SDK >=3.2.0
- Melos CLI: `dart pub global activate melos`

## Getting Started

1. **Bootstrap the workspace** (install dependencies for all packages):
   ```bash
   melos bootstrap
   ```

2. **Run common commands**:
   ```bash
   # Analyze all packages
   melos run analyze
   
   # Format code
   melos run format
   
   # Run tests
   melos run test
   
   # Get dependencies
   melos run get
   
   # Clean all packages
   melos run clean
   ```

## Creating a New Package

1. Create a new directory in `packages/` or `apps/`
2. Initialize with `dart create`
3. Run `melos bootstrap` to link dependencies

## Testing

This project provides multiple convenient ways to run tests across all packages. For detailed testing instructions, see [TESTING.md](TESTING.md).

**Quick Start:**
```bash
# PowerShell (Windows)
./test.ps1 -All

# Batch (Windows)
test.bat all

# Make (Unix/Linux/macOS)  
make test-all

# Melos (Cross-platform)
melos run test:all
```

## Development Workflow

1. Make changes in any package
2. Run tests using your preferred method (see [TESTING.md](TESTING.md))
3. Run `melos run analyze` to check for issues
4. Run `melos run format` before committing
5. Commit your changes

## Package Dependencies

Packages can depend on each other using path dependencies. Melos automatically manages these during bootstrap.

Example in `pubspec.yaml`:
```yaml
dependencies:
  ermes_core:
    path: ../core
```

## Version Management

Use Melos versioning commands to manage package versions:
```bash
melos version
```

## CI/CD Integration

The monorepo is designed to work with CI/CD pipelines. See `.github/workflows` for examples.

## License

[Your License Here]
