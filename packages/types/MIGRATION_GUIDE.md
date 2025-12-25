# TypeScript to Dart Migration - Ermes Types

## Overview

This document provides a detailed comparison between the original TypeScript implementation and the new Dart implementation of the Ermes Types package.

## Package Structure

### TypeScript
```
types/
├── src/
│   ├── ErmesType.ts
│   ├── PaginationTypes.ts
│   ├── SignalingType.ts
│   └── index.ts
├── dist/               # Compiled output
├── package.json
└── tsconfig.json
```

### Dart
```
types/
├── lib/
│   ├── ermes_types.dart          # Main export
│   └── src/
│       ├── ermes_types.dart
│       ├── pagination_types.dart
│       ├── signaling_types.dart
│       └── type_aliases.dart
├── test/
├── example/
├── pubspec.yaml
└── build.yaml
```

## Type System Comparison

### Enums

**TypeScript:**
```typescript
export enum MessageValue {
    base,
    chunk,
    service,
}
```

**Dart:**
```dart
enum MessageValue {
  base,
  chunk,
  service,
}
```

**Notes**: Nearly identical, but Dart enums are more powerful with enhanced enums (Dart 2.17+).

### Type Aliases

**TypeScript:**
```typescript
export type IdType = number;
export type IdPeer = string;
export type TypeOfData = Uint8Array;
```

**Dart:**
```dart
typedef IdType = int;
typedef IdPeer = String;
typedef TypeOfData = Uint8List;
```

**Notes**: Direct mapping, but Dart uses `Uint8List` instead of `Uint8Array`.

### Union Types

**TypeScript:**
```typescript
export type ServiceReason = 'c' | 's' | 'x'
export type MessageType = MessageData | ChunkMessage | ServiceMessage
export type IntegrityCheckType = string | number | boolean
```

**Dart:**
```dart
// String literals become typedef
typedef ServiceReason = String;

// Union types use Freezed
@freezed
class MessageType with _$MessageType {
  const factory MessageType.data(MessageData message) = MessageTypeData;
  const factory MessageType.chunk(ChunkMessage message) = MessageTypeChunk;
  const factory MessageType.service(ServiceMessage message) = MessageTypeService;
}

// Multi-type unions use Object supertype
typedef IntegrityCheckType = Object; // Can be String, int, or bool
```

**Notes**: Dart doesn't have native union types. Freezed provides sealed classes for type-safe unions.

### Interfaces

**TypeScript:**
```typescript
export interface MessageWithId {
    id: IdType;
}

export interface ISignalInfo {
    signalData: SignalData;
    isOffer(): boolean;
    isAnswer(): boolean;
    getSignalData(): SignalData;
}
```

**Dart:**
```dart
abstract class MessageWithId {
  int get id;
}

abstract class ISignalInfo {
  SignalData get signalData;
  bool isOffer();
  bool isAnswer();
  SignalData getSignalData();
}
```

**Notes**: Dart uses abstract classes for interfaces. Getters are preferred over fields.

### Generic Types

**TypeScript:**
```typescript
export type MessageDataGeneric<DataType> = MessageWithId & {
    data: DataType;
}

export type PaginationDTO<ListType, CursorType> = {
    cursor: CursorType;
    items: ListType[];
    // ...
}
```

**Dart:**
```dart
@freezed
class MessageDataGeneric<T> with _$MessageDataGeneric<T> {
  const factory MessageDataGeneric({
    required int id,
    required T data,
  }) = _MessageDataGeneric<T>;
}

@freezed
class PaginationDto<T, C> with _$PaginationDto<T, C> {
  const factory PaginationDto({
    required C cursor,
    required List<T> items,
    // ...
  }) = _PaginationDto<T, C>;
}
```

**Notes**: Dart generics are similar but must be declared with Freezed for immutable classes.

### Callback Types

**TypeScript:**
```typescript
export type CallbackOnMessage = (message: MessageType) => void
export type CallbackOnDataArrivedFrom = (
    data: TypeOfDataExternal,
    peer: IdPeer
) => void;
```

**Dart:**
```dart
typedef CallbackOnMessage = void Function(MessageType message);
typedef CallbackOnDataArrivedFrom = void Function(
  TypeOfDataExternal data,
  IdPeer peer,
);
```

**Notes**: Dart uses `Function` type with `typedef` for callback definitions.

## Data Classes Comparison

### Basic Class

**TypeScript:**
```typescript
export type MessageData = MessageDataGeneric<TypeOfData> & MessageWithId & {}
```

**Dart:**
```dart
@freezed
class MessageData with _$MessageData implements MessageWithId {
  const factory MessageData({
    required int id,
    required Uint8List data,
  }) = _MessageData;

  factory MessageData.fromJson(Map<String, dynamic> json) =>
      _$MessageDataFromJson(json);
}
```

**Notes**: 
- Dart version is more verbose but provides immutability, JSON serialization, and more features
- TypeScript uses intersection types (`&`), Dart uses `implements`

### Class with Optional Fields

**TypeScript:**
```typescript
export type ServiceMessage = MessageWithId & {
    arrayChunkInfo?: ChunkInfo[];
    arrayId?: IdType[];
    reason: ServiceReason;
};
```

**Dart:**
```dart
@freezed
class ServiceMessage with _$ServiceMessage implements MessageWithId {
  const factory ServiceMessage({
    required int id,
    required String reason,
    List<ChunkInfo>? arrayChunkInfo,
    List<int>? arrayId,
  }) = _ServiceMessage;

  factory ServiceMessage.fromJson(Map<String, dynamic> json) =>
      _$ServiceMessageFromJson(json);
}
```

**Notes**:
- TypeScript uses `?` suffix for optionals
- Dart uses `?` suffix for nullable types
- Dart requires explicit `required` keyword for mandatory fields

### Interface with Methods

**TypeScript:**
```typescript
export interface ISignalInfoOffer extends ISignalInfo {
    reusableOffer: ReusableOffer;  
    getOfferInfo(): ReusableOffer;
}
```

**Dart:**
```dart
@freezed
class SignalInfoOffer with _$SignalInfoOffer implements ISignalInfo {
  const SignalInfoOffer._(); // For custom methods

  const factory SignalInfoOffer({
    required SignalData signalData,
    required ReusableOffer reusableOffer,
  }) = _SignalInfoOffer;

  @override
  bool isOffer() => true;

  @override
  bool isAnswer() => false;

  @override
  SignalData getSignalData() => signalData;

  ReusableOffer getOfferInfo() => reusableOffer;

  factory SignalInfoOffer.fromJson(Map<String, dynamic> json) =>
      _$SignalInfoOfferFromJson(json);
}
```

**Notes**: Dart requires a private constructor `const SignalInfoOffer._()` to add custom methods to Freezed classes.

## Features Comparison

### TypeScript Features
- ✅ Structural typing
- ✅ Union types with `|`
- ✅ Type inference
- ✅ Optional chaining `?.`
- ✅ Nullish coalescing `??`
- ❌ No built-in immutability
- ❌ Manual JSON serialization
- ❌ No pattern matching

### Dart Features
- ✅ Nominal typing (stronger type safety)
- ✅ Built-in immutability (with Freezed)
- ✅ Automatic JSON serialization
- ✅ Pattern matching (with Freezed)
- ✅ Sound null safety
- ✅ Extension methods
- ✅ Const constructors
- ✅ Union types (with Freezed)

## Usage Comparison

### Creating Instances

**TypeScript:**
```typescript
const message: MessageData = {
    id: 1,
    data: new Uint8Array([1, 2, 3])
};
```

**Dart:**
```dart
final message = MessageData(
  id: 1,
  data: Uint8List.fromList([1, 2, 3]),
);
```

### Pattern Matching / Type Guards

**TypeScript:**
```typescript
function handleMessage(message: MessageType) {
    if ('data' in message && 'refId' in message) {
        // It's a ChunkMessage
        console.log(`Chunk ${message.index}/${message.roof}`);
    } else if ('reason' in message) {
        // It's a ServiceMessage
        console.log(`Service: ${message.reason}`);
    } else {
        // It's a MessageData
        console.log(`Data message: ${message.id}`);
    }
}
```

**Dart:**
```dart
void handleMessage(MessageType message) {
  message.when(
    data: (msg) => print('Data message: ${msg.id}'),
    chunk: (msg) => print('Chunk ${msg.index}/${msg.roof}'),
    service: (msg) => print('Service: ${msg.reason}'),
  );
}
```

**Notes**: Dart's pattern matching is exhaustive and type-safe, compiler will error if a case is missing.

### Copying with Changes

**TypeScript:**
```typescript
const updated = {
    ...original,
    id: 2,
    data: newData
};
```

**Dart:**
```dart
final updated = original.copyWith(
  id: 2,
  data: newData,
);
```

**Notes**: Dart's `copyWith` is type-safe and generated automatically by Freezed.

### JSON Serialization

**TypeScript:**
```typescript
// Manual serialization typically required
const json = JSON.stringify(message);
const parsed = JSON.parse(json) as MessageData;
```

**Dart:**
```dart
// Automatic with Freezed + json_serializable
final json = message.toJson();
final parsed = MessageData.fromJson(json);
```

**Notes**: Dart provides compile-time safe JSON serialization.

## Migration Benefits

### Type Safety
- Dart's nominal typing catches more errors at compile time
- Sound null safety eliminates entire categories of bugs
- Exhaustive pattern matching ensures all cases are handled

### Immutability
- All Freezed classes are deeply immutable
- Prevents accidental mutations
- Makes concurrent programming safer

### Developer Experience
- Auto-completion works better with concrete types
- `copyWith` makes updates easier and safer
- Pattern matching is more readable than type guards

### Performance
- Ahead-of-time compilation for better runtime performance
- Smaller code size in production
- Better tree-shaking

## Migration Challenges

### Learning Curve
- Freezed requires understanding code generation
- Pattern matching is a new concept for TypeScript developers
- Dart's type system is more strict

### Tooling
- Need to run code generation (`build_runner`)
- More build steps than TypeScript
- Generated files must be managed

### Verbosity
- Dart code is generally more verbose
- More boilerplate for simple types
- Need explicit type annotations more often

## Best Practices

### TypeScript
```typescript
// Use type aliases for brevity
export type MessageType = MessageData | ChunkMessage | ServiceMessage;

// Use optional chaining
const chunkInfo = message.arrayChunkInfo?.[0]?.index;

// Use discriminated unions
type Result<T> = { success: true; data: T } | { success: false; error: string };
```

### Dart
```dart
// Use Freezed for data classes
@freezed
class MessageType with _$MessageType { /* ... */ }

// Use null-aware operators
final chunkInfo = message.arrayChunkInfo?.first.index;

// Use pattern matching
result.when(
  success: (data) => handleSuccess(data),
  error: (error) => handleError(error),
);
```

## Conclusion

The Dart version provides:
- ✅ Stronger type safety
- ✅ Built-in immutability
- ✅ Automatic JSON serialization
- ✅ Better pattern matching
- ✅ Sound null safety

At the cost of:
- ❌ More verbosity
- ❌ Code generation requirement
- ❌ Steeper learning curve

The trade-off is worthwhile for projects that value type safety, maintainability, and runtime reliability.
