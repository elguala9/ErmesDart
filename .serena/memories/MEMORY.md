# ErmesDart Project Memory

## Barrel Files Configuration

**System:**
- ALL packages use `barrel_files_annotation` with `@includeInBarrelFile` for marking exportable classes
- All packages have `barrel_files: ^0.3.0` as dev_dependency
- Barrel generation uses build_runner with `--delete-conflicting-outputs` flag

**How to generate/update barrels:**
1. From root: `melos run barrels` (generates for all packages)
2. From single package: `dart run build_runner build --delete-conflicting-outputs`
3. Individual script: `dart pub run barrels` in the package directory

**How to add new exports:**
1. Add import: `import 'package:barrel_files_annotation/barrel_files_annotation.dart';`
2. Add annotation: `@includeInBarrelFile` before the class/function
3. Run `melos run barrels` to auto-generate barrel exports

**Configuration:**
- Each package has script `barrels: dart pub global run barrel_files:barrel_files`
- Root pubspec.yaml has melos command `barrels` using global barrel_files runner
- Install globally first: `dart pub global activate barrel_files`
- Runs using stable global command (avoids build_runner version conflicts)

**SingletonManager:**
- Created `GenericObjectManager<K, V>` in `packages/iermes/lib/src/managers/generic_object_manager.dart`
- Manages key->object mapping with generic types (K, V)
- Exported in `iermes.dart`
- Uses composite key based on type names for singleton isolation

**ErmesPeerCipherHandler:**
- Singleton in `packages/ermes_cipher/lib/src/ermes_peer_cipher_handler.dart`
- Manages `String (peerId) -> ErmesPeerCipher` mapping
- Methods: `setCipher()`, `getCipher()`, `removeCipher()`, `hasCipher()`, `clearAll()`
- Exported in `ermes_cipher.dart`
