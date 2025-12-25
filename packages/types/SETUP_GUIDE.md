# Ermes Types - Setup and Code Generation Guide

## Initial Setup

### 1. Install Dependencies

From the package directory:

```bash
cd packages/types
dart pub get
```

This will install all dependencies including:
- freezed_annotation
- json_annotation
- build_runner (dev)
- freezed (dev)
- json_serializable (dev)

### 2. Generate Freezed Code

The package uses Freezed for immutable data classes and union types. You need to generate the `.freezed.dart` and `.g.dart` files:

```bash
# One-time generation
dart run build_runner build --delete-conflicting-outputs

# Or watch for changes (recommended during development)
dart run build_runner watch --delete-conflicting-outputs
```

**Note**: The generated files are gitignored. You'll need to run code generation after cloning the repository.

### 3. Run Tests

After code generation:

```bash
dart test
```

All tests should pass.

### 4. Run Example

```bash
dart run example/ermes_types_example.dart
```

## Development Workflow

### Making Changes to Types

1. Edit the source files in `lib/src/`
2. If you're using watch mode, changes will be detected automatically
3. Otherwise, run: `dart run build_runner build --delete-conflicting-outputs`
4. Run tests to verify: `dart test`

### Adding New Types

1. Create your type using Freezed annotations:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_new_type.freezed.dart';
part 'my_new_type.g.dart';

@freezed
class MyNewType with _$MyNewType {
  const factory MyNewType({
    required String id,
    required String name,
  }) = _MyNewType;

  factory MyNewType.fromJson(Map<String, dynamic> json) =>
      _$MyNewTypeFromJson(json);
}
```

2. Export it in `lib/ermes_types.dart`:

```dart
export 'src/my_new_type.dart';
```

3. Generate code: `dart run build_runner build --delete-conflicting-outputs`

4. Add tests in `test/`

### Union Types

For union types (like MessageType):

```dart
@freezed
class MyUnion with _$MyUnion {
  const factory MyUnion.typeA(TypeA data) = MyUnionTypeA;
  const factory MyUnion.typeB(TypeB data) = MyUnionTypeB;

  factory MyUnion.fromJson(Map<String, dynamic> json) =>
      _$MyUnionFromJson(json);
}
```

### Custom Methods in Freezed Classes

To add custom methods, use a private constructor:

```dart
@freezed
class MyType with _$MyType {
  const MyType._(); // Private constructor for custom methods

  const factory MyType({
    required String value,
  }) = _MyType;

  // Custom method
  bool isValid() => value.isNotEmpty;

  factory MyType.fromJson(Map<String, dynamic> json) =>
      _$MyTypeFromJson(json);
}
```

## Troubleshooting

### Build Runner Issues

**Problem**: Build fails with conflicts

**Solution**: Use `--delete-conflicting-outputs` flag:
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Problem**: Generated files not updating

**Solution**: Clean and rebuild:
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Import Errors

**Problem**: Cannot find generated files

**Solution**: Make sure you've run code generation:
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Problem**: Part directive errors

**Solution**: Ensure your part declarations match the generated file names:
```dart
part 'my_type.freezed.dart';  // Must match filename
part 'my_type.g.dart';         // Must match filename
```

### Test Failures

**Problem**: Tests fail after adding new types

**Solution**: 
1. Ensure code generation completed successfully
2. Check that all required fields are provided in tests
3. Verify JSON serialization is working correctly

## Integration with Monorepo

### From Root Directory

```bash
# Bootstrap all packages
melos bootstrap

# Generate code in all packages
melos run build

# Run tests in all packages
melos run test
```

### From CLI or Other Packages

To use ermes_types in other packages:

```yaml
# In your pubspec.yaml
dependencies:
  ermes_types:
    path: ../../packages/types
```

Then:
```bash
melos bootstrap
```

## CI/CD Considerations

In CI/CD pipelines, you'll need to:

1. Install dependencies: `dart pub get`
2. Generate code: `dart run build_runner build --delete-conflicting-outputs`
3. Run tests: `dart test`

Example GitHub Actions:
```yaml
- name: Get dependencies
  run: dart pub get
  
- name: Generate code
  run: dart run build_runner build --delete-conflicting-outputs
  
- name: Run tests
  run: dart test
```

## Performance Tips

### Watch Mode

During development, use watch mode to automatically regenerate code:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

This watches for file changes and regenerates code automatically.

### Build Cache

Build runner caches results. To clear the cache:

```bash
dart run build_runner clean
```

Then rebuild:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Migration from TypeScript

The types in this package correspond to the TypeScript version as follows:

| TypeScript | Dart |
|------------|------|
| `interface` | `abstract class` or `@freezed` |
| `type union \| types` | `@freezed` union |
| `type alias = ...` | `typedef` |
| Optional `?` | Nullable `?` |
| `Array<T>` | `List<T>` |
| `Uint8Array` | `Uint8List` |

### Key Differences

1. **Immutability**: All Dart types are immutable by default (Freezed)
2. **Pattern Matching**: Use `.when()` or `.map()` for union types
3. **JSON**: Built-in support with `.toJson()` and `.fromJson()`
4. **Code Generation**: Required for Freezed classes

## Additional Resources

- [Freezed Documentation](https://pub.dev/packages/freezed)
- [JSON Serialization](https://pub.dev/packages/json_serializable)
- [Build Runner](https://pub.dev/packages/build_runner)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
