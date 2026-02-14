// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ermes_types.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MessageRoot {
  /// Serialized message data
  @Uint8ListConverter()
  Uint8List get messageSerialized => throw _privateConstructorUsedError;

  /// Integrity check value (can be String, int, or bool)
  Object get integrityCheckValue => throw _privateConstructorUsedError;

  /// Create a copy of MessageRoot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageRootCopyWith<MessageRoot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageRootCopyWith<$Res> {
  factory $MessageRootCopyWith(
    MessageRoot value,
    $Res Function(MessageRoot) then,
  ) = _$MessageRootCopyWithImpl<$Res, MessageRoot>;
  @useResult
  $Res call({
    @Uint8ListConverter() Uint8List messageSerialized,
    Object integrityCheckValue,
  });
}

/// @nodoc
class _$MessageRootCopyWithImpl<$Res, $Val extends MessageRoot>
    implements $MessageRootCopyWith<$Res> {
  _$MessageRootCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageRoot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageSerialized = null,
    Object? integrityCheckValue = null,
  }) {
    return _then(
      _value.copyWith(
            messageSerialized: null == messageSerialized
                ? _value.messageSerialized
                : messageSerialized // ignore: cast_nullable_to_non_nullable
                      as Uint8List,
            integrityCheckValue: null == integrityCheckValue
                ? _value.integrityCheckValue
                : integrityCheckValue,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageRootImplCopyWith<$Res>
    implements $MessageRootCopyWith<$Res> {
  factory _$$MessageRootImplCopyWith(
    _$MessageRootImpl value,
    $Res Function(_$MessageRootImpl) then,
  ) = __$$MessageRootImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @Uint8ListConverter() Uint8List messageSerialized,
    Object integrityCheckValue,
  });
}

/// @nodoc
class __$$MessageRootImplCopyWithImpl<$Res>
    extends _$MessageRootCopyWithImpl<$Res, _$MessageRootImpl>
    implements _$$MessageRootImplCopyWith<$Res> {
  __$$MessageRootImplCopyWithImpl(
    _$MessageRootImpl _value,
    $Res Function(_$MessageRootImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageRoot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageSerialized = null,
    Object? integrityCheckValue = null,
  }) {
    return _then(
      _$MessageRootImpl(
        messageSerialized: null == messageSerialized
            ? _value.messageSerialized
            : messageSerialized // ignore: cast_nullable_to_non_nullable
                  as Uint8List,
        integrityCheckValue: null == integrityCheckValue
            ? _value.integrityCheckValue
            : integrityCheckValue,
      ),
    );
  }
}

/// @nodoc

class _$MessageRootImpl implements _MessageRoot {
  const _$MessageRootImpl({
    @Uint8ListConverter() required this.messageSerialized,
    required this.integrityCheckValue,
  });

  /// Serialized message data
  @override
  @Uint8ListConverter()
  final Uint8List messageSerialized;

  /// Integrity check value (can be String, int, or bool)
  @override
  final Object integrityCheckValue;

  @override
  String toString() {
    return 'MessageRoot(messageSerialized: $messageSerialized, integrityCheckValue: $integrityCheckValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageRootImpl &&
            const DeepCollectionEquality().equals(
              other.messageSerialized,
              messageSerialized,
            ) &&
            const DeepCollectionEquality().equals(
              other.integrityCheckValue,
              integrityCheckValue,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(messageSerialized),
    const DeepCollectionEquality().hash(integrityCheckValue),
  );

  /// Create a copy of MessageRoot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageRootImplCopyWith<_$MessageRootImpl> get copyWith =>
      __$$MessageRootImplCopyWithImpl<_$MessageRootImpl>(this, _$identity);
}

abstract class _MessageRoot implements MessageRoot {
  const factory _MessageRoot({
    @Uint8ListConverter() required final Uint8List messageSerialized,
    required final Object integrityCheckValue,
  }) = _$MessageRootImpl;

  /// Serialized message data
  @override
  @Uint8ListConverter()
  Uint8List get messageSerialized;

  /// Integrity check value (can be String, int, or bool)
  @override
  Object get integrityCheckValue;

  /// Create a copy of MessageRoot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageRootImplCopyWith<_$MessageRootImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$InternalMessage {
  /// The actual message content
  MessageType get message => throw _privateConstructorUsedError;

  /// Type of message
  MessageValue get type => throw _privateConstructorUsedError;

  /// Create a copy of InternalMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InternalMessageCopyWith<InternalMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InternalMessageCopyWith<$Res> {
  factory $InternalMessageCopyWith(
    InternalMessage value,
    $Res Function(InternalMessage) then,
  ) = _$InternalMessageCopyWithImpl<$Res, InternalMessage>;
  @useResult
  $Res call({MessageType message, MessageValue type});

  $MessageTypeCopyWith<$Res> get message;
}

/// @nodoc
class _$InternalMessageCopyWithImpl<$Res, $Val extends InternalMessage>
    implements $InternalMessageCopyWith<$Res> {
  _$InternalMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InternalMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? type = null}) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as MessageType,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as MessageValue,
          )
          as $Val,
    );
  }

  /// Create a copy of InternalMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageTypeCopyWith<$Res> get message {
    return $MessageTypeCopyWith<$Res>(_value.message, (value) {
      return _then(_value.copyWith(message: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$InternalMessageImplCopyWith<$Res>
    implements $InternalMessageCopyWith<$Res> {
  factory _$$InternalMessageImplCopyWith(
    _$InternalMessageImpl value,
    $Res Function(_$InternalMessageImpl) then,
  ) = __$$InternalMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({MessageType message, MessageValue type});

  @override
  $MessageTypeCopyWith<$Res> get message;
}

/// @nodoc
class __$$InternalMessageImplCopyWithImpl<$Res>
    extends _$InternalMessageCopyWithImpl<$Res, _$InternalMessageImpl>
    implements _$$InternalMessageImplCopyWith<$Res> {
  __$$InternalMessageImplCopyWithImpl(
    _$InternalMessageImpl _value,
    $Res Function(_$InternalMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InternalMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? type = null}) {
    return _then(
      _$InternalMessageImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as MessageType,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as MessageValue,
      ),
    );
  }
}

/// @nodoc

class _$InternalMessageImpl implements _InternalMessage {
  const _$InternalMessageImpl({required this.message, required this.type});

  /// The actual message content
  @override
  final MessageType message;

  /// Type of message
  @override
  final MessageValue type;

  @override
  String toString() {
    return 'InternalMessage(message: $message, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InternalMessageImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.type, type) || other.type == type));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, type);

  /// Create a copy of InternalMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InternalMessageImplCopyWith<_$InternalMessageImpl> get copyWith =>
      __$$InternalMessageImplCopyWithImpl<_$InternalMessageImpl>(
        this,
        _$identity,
      );
}

abstract class _InternalMessage implements InternalMessage {
  const factory _InternalMessage({
    required final MessageType message,
    required final MessageValue type,
  }) = _$InternalMessageImpl;

  /// The actual message content
  @override
  MessageType get message;

  /// Type of message
  @override
  MessageValue get type;

  /// Create a copy of InternalMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InternalMessageImplCopyWith<_$InternalMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MessageData {
  /// Unique message identifier
  int get id => throw _privateConstructorUsedError;

  /// Message payload data
  @Uint8ListConverter()
  Uint8List get data => throw _privateConstructorUsedError;

  /// Create a copy of MessageData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageDataCopyWith<MessageData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageDataCopyWith<$Res> {
  factory $MessageDataCopyWith(
    MessageData value,
    $Res Function(MessageData) then,
  ) = _$MessageDataCopyWithImpl<$Res, MessageData>;
  @useResult
  $Res call({int id, @Uint8ListConverter() Uint8List data});
}

/// @nodoc
class _$MessageDataCopyWithImpl<$Res, $Val extends MessageData>
    implements $MessageDataCopyWith<$Res> {
  _$MessageDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? data = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Uint8List,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageDataImplCopyWith<$Res>
    implements $MessageDataCopyWith<$Res> {
  factory _$$MessageDataImplCopyWith(
    _$MessageDataImpl value,
    $Res Function(_$MessageDataImpl) then,
  ) = __$$MessageDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, @Uint8ListConverter() Uint8List data});
}

/// @nodoc
class __$$MessageDataImplCopyWithImpl<$Res>
    extends _$MessageDataCopyWithImpl<$Res, _$MessageDataImpl>
    implements _$$MessageDataImplCopyWith<$Res> {
  __$$MessageDataImplCopyWithImpl(
    _$MessageDataImpl _value,
    $Res Function(_$MessageDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? data = null}) {
    return _then(
      _$MessageDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as Uint8List,
      ),
    );
  }
}

/// @nodoc

class _$MessageDataImpl implements _MessageData {
  const _$MessageDataImpl({
    required this.id,
    @Uint8ListConverter() required this.data,
  });

  /// Unique message identifier
  @override
  final int id;

  /// Message payload data
  @override
  @Uint8ListConverter()
  final Uint8List data;

  @override
  String toString() {
    return 'MessageData(id: $id, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, const DeepCollectionEquality().hash(data));

  /// Create a copy of MessageData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageDataImplCopyWith<_$MessageDataImpl> get copyWith =>
      __$$MessageDataImplCopyWithImpl<_$MessageDataImpl>(this, _$identity);
}

abstract class _MessageData implements MessageData {
  const factory _MessageData({
    required final int id,
    @Uint8ListConverter() required final Uint8List data,
  }) = _$MessageDataImpl;

  /// Unique message identifier
  @override
  int get id;

  /// Message payload data
  @override
  @Uint8ListConverter()
  Uint8List get data;

  /// Create a copy of MessageData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageDataImplCopyWith<_$MessageDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MessageDataGeneric<T> {
  /// Unique message identifier
  int get id => throw _privateConstructorUsedError;

  /// Message payload data
  T get data => throw _privateConstructorUsedError;

  /// Create a copy of MessageDataGeneric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageDataGenericCopyWith<T, MessageDataGeneric<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageDataGenericCopyWith<T, $Res> {
  factory $MessageDataGenericCopyWith(
    MessageDataGeneric<T> value,
    $Res Function(MessageDataGeneric<T>) then,
  ) = _$MessageDataGenericCopyWithImpl<T, $Res, MessageDataGeneric<T>>;
  @useResult
  $Res call({int id, T data});
}

/// @nodoc
class _$MessageDataGenericCopyWithImpl<
  T,
  $Res,
  $Val extends MessageDataGeneric<T>
>
    implements $MessageDataGenericCopyWith<T, $Res> {
  _$MessageDataGenericCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageDataGeneric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? data = freezed}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            data: freezed == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as T,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageDataGenericImplCopyWith<T, $Res>
    implements $MessageDataGenericCopyWith<T, $Res> {
  factory _$$MessageDataGenericImplCopyWith(
    _$MessageDataGenericImpl<T> value,
    $Res Function(_$MessageDataGenericImpl<T>) then,
  ) = __$$MessageDataGenericImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({int id, T data});
}

/// @nodoc
class __$$MessageDataGenericImplCopyWithImpl<T, $Res>
    extends
        _$MessageDataGenericCopyWithImpl<T, $Res, _$MessageDataGenericImpl<T>>
    implements _$$MessageDataGenericImplCopyWith<T, $Res> {
  __$$MessageDataGenericImplCopyWithImpl(
    _$MessageDataGenericImpl<T> _value,
    $Res Function(_$MessageDataGenericImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageDataGeneric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? data = freezed}) {
    return _then(
      _$MessageDataGenericImpl<T>(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        data: freezed == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as T,
      ),
    );
  }
}

/// @nodoc

class _$MessageDataGenericImpl<T> implements _MessageDataGeneric<T> {
  const _$MessageDataGenericImpl({required this.id, required this.data});

  /// Unique message identifier
  @override
  final int id;

  /// Message payload data
  @override
  final T data;

  @override
  String toString() {
    return 'MessageDataGeneric<$T>(id: $id, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageDataGenericImpl<T> &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, const DeepCollectionEquality().hash(data));

  /// Create a copy of MessageDataGeneric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageDataGenericImplCopyWith<T, _$MessageDataGenericImpl<T>>
  get copyWith =>
      __$$MessageDataGenericImplCopyWithImpl<T, _$MessageDataGenericImpl<T>>(
        this,
        _$identity,
      );
}

abstract class _MessageDataGeneric<T> implements MessageDataGeneric<T> {
  const factory _MessageDataGeneric({
    required final int id,
    required final T data,
  }) = _$MessageDataGenericImpl<T>;

  /// Unique message identifier
  @override
  int get id;

  /// Message payload data
  @override
  T get data;

  /// Create a copy of MessageDataGeneric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageDataGenericImplCopyWith<T, _$MessageDataGenericImpl<T>>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ChunkMessage {
  /// Unique message identifier
  int get id => throw _privateConstructorUsedError;

  /// Message payload data
  @Uint8ListConverter()
  Uint8List get data => throw _privateConstructorUsedError;

  /// Reference ID linking all chunks of the same message
  String get refId => throw _privateConstructorUsedError;

  /// Index of this chunk in the sequence
  int get index => throw _privateConstructorUsedError;

  /// Total number of chunks (roof)
  int get roof => throw _privateConstructorUsedError;

  /// Create a copy of ChunkMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChunkMessageCopyWith<ChunkMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChunkMessageCopyWith<$Res> {
  factory $ChunkMessageCopyWith(
    ChunkMessage value,
    $Res Function(ChunkMessage) then,
  ) = _$ChunkMessageCopyWithImpl<$Res, ChunkMessage>;
  @useResult
  $Res call({
    int id,
    @Uint8ListConverter() Uint8List data,
    String refId,
    int index,
    int roof,
  });
}

/// @nodoc
class _$ChunkMessageCopyWithImpl<$Res, $Val extends ChunkMessage>
    implements $ChunkMessageCopyWith<$Res> {
  _$ChunkMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChunkMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? data = null,
    Object? refId = null,
    Object? index = null,
    Object? roof = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Uint8List,
            refId: null == refId
                ? _value.refId
                : refId // ignore: cast_nullable_to_non_nullable
                      as String,
            index: null == index
                ? _value.index
                : index // ignore: cast_nullable_to_non_nullable
                      as int,
            roof: null == roof
                ? _value.roof
                : roof // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChunkMessageImplCopyWith<$Res>
    implements $ChunkMessageCopyWith<$Res> {
  factory _$$ChunkMessageImplCopyWith(
    _$ChunkMessageImpl value,
    $Res Function(_$ChunkMessageImpl) then,
  ) = __$$ChunkMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    @Uint8ListConverter() Uint8List data,
    String refId,
    int index,
    int roof,
  });
}

/// @nodoc
class __$$ChunkMessageImplCopyWithImpl<$Res>
    extends _$ChunkMessageCopyWithImpl<$Res, _$ChunkMessageImpl>
    implements _$$ChunkMessageImplCopyWith<$Res> {
  __$$ChunkMessageImplCopyWithImpl(
    _$ChunkMessageImpl _value,
    $Res Function(_$ChunkMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChunkMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? data = null,
    Object? refId = null,
    Object? index = null,
    Object? roof = null,
  }) {
    return _then(
      _$ChunkMessageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        data: null == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as Uint8List,
        refId: null == refId
            ? _value.refId
            : refId // ignore: cast_nullable_to_non_nullable
                  as String,
        index: null == index
            ? _value.index
            : index // ignore: cast_nullable_to_non_nullable
                  as int,
        roof: null == roof
            ? _value.roof
            : roof // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ChunkMessageImpl implements _ChunkMessage {
  const _$ChunkMessageImpl({
    required this.id,
    @Uint8ListConverter() required this.data,
    required this.refId,
    required this.index,
    required this.roof,
  });

  /// Unique message identifier
  @override
  final int id;

  /// Message payload data
  @override
  @Uint8ListConverter()
  final Uint8List data;

  /// Reference ID linking all chunks of the same message
  @override
  final String refId;

  /// Index of this chunk in the sequence
  @override
  final int index;

  /// Total number of chunks (roof)
  @override
  final int roof;

  @override
  String toString() {
    return 'ChunkMessage(id: $id, data: $data, refId: $refId, index: $index, roof: $roof)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChunkMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other.data, data) &&
            (identical(other.refId, refId) || other.refId == refId) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.roof, roof) || other.roof == roof));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    const DeepCollectionEquality().hash(data),
    refId,
    index,
    roof,
  );

  /// Create a copy of ChunkMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChunkMessageImplCopyWith<_$ChunkMessageImpl> get copyWith =>
      __$$ChunkMessageImplCopyWithImpl<_$ChunkMessageImpl>(this, _$identity);
}

abstract class _ChunkMessage implements ChunkMessage {
  const factory _ChunkMessage({
    required final int id,
    @Uint8ListConverter() required final Uint8List data,
    required final String refId,
    required final int index,
    required final int roof,
  }) = _$ChunkMessageImpl;

  /// Unique message identifier
  @override
  int get id;

  /// Message payload data
  @override
  @Uint8ListConverter()
  Uint8List get data;

  /// Reference ID linking all chunks of the same message
  @override
  String get refId;

  /// Index of this chunk in the sequence
  @override
  int get index;

  /// Total number of chunks (roof)
  @override
  int get roof;

  /// Create a copy of ChunkMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChunkMessageImplCopyWith<_$ChunkMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ChunkMessageGeneric<T> {
  /// Unique message identifier
  int get id => throw _privateConstructorUsedError;

  /// Message payload data
  T get data => throw _privateConstructorUsedError;

  /// Reference ID linking all chunks
  String get refId => throw _privateConstructorUsedError;

  /// Index of this chunk
  int get index => throw _privateConstructorUsedError;

  /// Total number of chunks
  int get roof => throw _privateConstructorUsedError;

  /// Create a copy of ChunkMessageGeneric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChunkMessageGenericCopyWith<T, ChunkMessageGeneric<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChunkMessageGenericCopyWith<T, $Res> {
  factory $ChunkMessageGenericCopyWith(
    ChunkMessageGeneric<T> value,
    $Res Function(ChunkMessageGeneric<T>) then,
  ) = _$ChunkMessageGenericCopyWithImpl<T, $Res, ChunkMessageGeneric<T>>;
  @useResult
  $Res call({int id, T data, String refId, int index, int roof});
}

/// @nodoc
class _$ChunkMessageGenericCopyWithImpl<
  T,
  $Res,
  $Val extends ChunkMessageGeneric<T>
>
    implements $ChunkMessageGenericCopyWith<T, $Res> {
  _$ChunkMessageGenericCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChunkMessageGeneric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? data = freezed,
    Object? refId = null,
    Object? index = null,
    Object? roof = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            data: freezed == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as T,
            refId: null == refId
                ? _value.refId
                : refId // ignore: cast_nullable_to_non_nullable
                      as String,
            index: null == index
                ? _value.index
                : index // ignore: cast_nullable_to_non_nullable
                      as int,
            roof: null == roof
                ? _value.roof
                : roof // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChunkMessageGenericImplCopyWith<T, $Res>
    implements $ChunkMessageGenericCopyWith<T, $Res> {
  factory _$$ChunkMessageGenericImplCopyWith(
    _$ChunkMessageGenericImpl<T> value,
    $Res Function(_$ChunkMessageGenericImpl<T>) then,
  ) = __$$ChunkMessageGenericImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({int id, T data, String refId, int index, int roof});
}

/// @nodoc
class __$$ChunkMessageGenericImplCopyWithImpl<T, $Res>
    extends
        _$ChunkMessageGenericCopyWithImpl<T, $Res, _$ChunkMessageGenericImpl<T>>
    implements _$$ChunkMessageGenericImplCopyWith<T, $Res> {
  __$$ChunkMessageGenericImplCopyWithImpl(
    _$ChunkMessageGenericImpl<T> _value,
    $Res Function(_$ChunkMessageGenericImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of ChunkMessageGeneric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? data = freezed,
    Object? refId = null,
    Object? index = null,
    Object? roof = null,
  }) {
    return _then(
      _$ChunkMessageGenericImpl<T>(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        data: freezed == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as T,
        refId: null == refId
            ? _value.refId
            : refId // ignore: cast_nullable_to_non_nullable
                  as String,
        index: null == index
            ? _value.index
            : index // ignore: cast_nullable_to_non_nullable
                  as int,
        roof: null == roof
            ? _value.roof
            : roof // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ChunkMessageGenericImpl<T> implements _ChunkMessageGeneric<T> {
  const _$ChunkMessageGenericImpl({
    required this.id,
    required this.data,
    required this.refId,
    required this.index,
    required this.roof,
  });

  /// Unique message identifier
  @override
  final int id;

  /// Message payload data
  @override
  final T data;

  /// Reference ID linking all chunks
  @override
  final String refId;

  /// Index of this chunk
  @override
  final int index;

  /// Total number of chunks
  @override
  final int roof;

  @override
  String toString() {
    return 'ChunkMessageGeneric<$T>(id: $id, data: $data, refId: $refId, index: $index, roof: $roof)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChunkMessageGenericImpl<T> &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other.data, data) &&
            (identical(other.refId, refId) || other.refId == refId) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.roof, roof) || other.roof == roof));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    const DeepCollectionEquality().hash(data),
    refId,
    index,
    roof,
  );

  /// Create a copy of ChunkMessageGeneric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChunkMessageGenericImplCopyWith<T, _$ChunkMessageGenericImpl<T>>
  get copyWith =>
      __$$ChunkMessageGenericImplCopyWithImpl<T, _$ChunkMessageGenericImpl<T>>(
        this,
        _$identity,
      );
}

abstract class _ChunkMessageGeneric<T> implements ChunkMessageGeneric<T> {
  const factory _ChunkMessageGeneric({
    required final int id,
    required final T data,
    required final String refId,
    required final int index,
    required final int roof,
  }) = _$ChunkMessageGenericImpl<T>;

  /// Unique message identifier
  @override
  int get id;

  /// Message payload data
  @override
  T get data;

  /// Reference ID linking all chunks
  @override
  String get refId;

  /// Index of this chunk
  @override
  int get index;

  /// Total number of chunks
  @override
  int get roof;

  /// Create a copy of ChunkMessageGeneric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChunkMessageGenericImplCopyWith<T, _$ChunkMessageGenericImpl<T>>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ChunkInfo {
  /// Chunk identifier
  int get chunkId => throw _privateConstructorUsedError;

  /// Optional array of indices for this chunk
  List<int>? get index => throw _privateConstructorUsedError;

  /// Create a copy of ChunkInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChunkInfoCopyWith<ChunkInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChunkInfoCopyWith<$Res> {
  factory $ChunkInfoCopyWith(ChunkInfo value, $Res Function(ChunkInfo) then) =
      _$ChunkInfoCopyWithImpl<$Res, ChunkInfo>;
  @useResult
  $Res call({int chunkId, List<int>? index});
}

/// @nodoc
class _$ChunkInfoCopyWithImpl<$Res, $Val extends ChunkInfo>
    implements $ChunkInfoCopyWith<$Res> {
  _$ChunkInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChunkInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? chunkId = null, Object? index = freezed}) {
    return _then(
      _value.copyWith(
            chunkId: null == chunkId
                ? _value.chunkId
                : chunkId // ignore: cast_nullable_to_non_nullable
                      as int,
            index: freezed == index
                ? _value.index
                : index // ignore: cast_nullable_to_non_nullable
                      as List<int>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChunkInfoImplCopyWith<$Res>
    implements $ChunkInfoCopyWith<$Res> {
  factory _$$ChunkInfoImplCopyWith(
    _$ChunkInfoImpl value,
    $Res Function(_$ChunkInfoImpl) then,
  ) = __$$ChunkInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int chunkId, List<int>? index});
}

/// @nodoc
class __$$ChunkInfoImplCopyWithImpl<$Res>
    extends _$ChunkInfoCopyWithImpl<$Res, _$ChunkInfoImpl>
    implements _$$ChunkInfoImplCopyWith<$Res> {
  __$$ChunkInfoImplCopyWithImpl(
    _$ChunkInfoImpl _value,
    $Res Function(_$ChunkInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChunkInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? chunkId = null, Object? index = freezed}) {
    return _then(
      _$ChunkInfoImpl(
        chunkId: null == chunkId
            ? _value.chunkId
            : chunkId // ignore: cast_nullable_to_non_nullable
                  as int,
        index: freezed == index
            ? _value._index
            : index // ignore: cast_nullable_to_non_nullable
                  as List<int>?,
      ),
    );
  }
}

/// @nodoc

class _$ChunkInfoImpl implements _ChunkInfo {
  const _$ChunkInfoImpl({required this.chunkId, final List<int>? index})
    : _index = index;

  /// Chunk identifier
  @override
  final int chunkId;

  /// Optional array of indices for this chunk
  final List<int>? _index;

  /// Optional array of indices for this chunk
  @override
  List<int>? get index {
    final value = _index;
    if (value == null) return null;
    if (_index is EqualUnmodifiableListView) return _index;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ChunkInfo(chunkId: $chunkId, index: $index)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChunkInfoImpl &&
            (identical(other.chunkId, chunkId) || other.chunkId == chunkId) &&
            const DeepCollectionEquality().equals(other._index, _index));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    chunkId,
    const DeepCollectionEquality().hash(_index),
  );

  /// Create a copy of ChunkInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChunkInfoImplCopyWith<_$ChunkInfoImpl> get copyWith =>
      __$$ChunkInfoImplCopyWithImpl<_$ChunkInfoImpl>(this, _$identity);
}

abstract class _ChunkInfo implements ChunkInfo {
  const factory _ChunkInfo({
    required final int chunkId,
    final List<int>? index,
  }) = _$ChunkInfoImpl;

  /// Chunk identifier
  @override
  int get chunkId;

  /// Optional array of indices for this chunk
  @override
  List<int>? get index;

  /// Create a copy of ChunkInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChunkInfoImplCopyWith<_$ChunkInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ServiceMessage {
  /// Unique message identifier
  int get id => throw _privateConstructorUsedError;

  /// Reason/command code ('c', 's', or 'x')
  String get reason => throw _privateConstructorUsedError;

  /// Optional array of chunk information
  List<ChunkInfo>? get arrayChunkInfo => throw _privateConstructorUsedError;

  /// Optional array of message IDs
  List<int>? get arrayId => throw _privateConstructorUsedError;

  /// Create a copy of ServiceMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServiceMessageCopyWith<ServiceMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServiceMessageCopyWith<$Res> {
  factory $ServiceMessageCopyWith(
    ServiceMessage value,
    $Res Function(ServiceMessage) then,
  ) = _$ServiceMessageCopyWithImpl<$Res, ServiceMessage>;
  @useResult
  $Res call({
    int id,
    String reason,
    List<ChunkInfo>? arrayChunkInfo,
    List<int>? arrayId,
  });
}

/// @nodoc
class _$ServiceMessageCopyWithImpl<$Res, $Val extends ServiceMessage>
    implements $ServiceMessageCopyWith<$Res> {
  _$ServiceMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServiceMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reason = null,
    Object? arrayChunkInfo = freezed,
    Object? arrayId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            arrayChunkInfo: freezed == arrayChunkInfo
                ? _value.arrayChunkInfo
                : arrayChunkInfo // ignore: cast_nullable_to_non_nullable
                      as List<ChunkInfo>?,
            arrayId: freezed == arrayId
                ? _value.arrayId
                : arrayId // ignore: cast_nullable_to_non_nullable
                      as List<int>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ServiceMessageImplCopyWith<$Res>
    implements $ServiceMessageCopyWith<$Res> {
  factory _$$ServiceMessageImplCopyWith(
    _$ServiceMessageImpl value,
    $Res Function(_$ServiceMessageImpl) then,
  ) = __$$ServiceMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String reason,
    List<ChunkInfo>? arrayChunkInfo,
    List<int>? arrayId,
  });
}

/// @nodoc
class __$$ServiceMessageImplCopyWithImpl<$Res>
    extends _$ServiceMessageCopyWithImpl<$Res, _$ServiceMessageImpl>
    implements _$$ServiceMessageImplCopyWith<$Res> {
  __$$ServiceMessageImplCopyWithImpl(
    _$ServiceMessageImpl _value,
    $Res Function(_$ServiceMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ServiceMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reason = null,
    Object? arrayChunkInfo = freezed,
    Object? arrayId = freezed,
  }) {
    return _then(
      _$ServiceMessageImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        arrayChunkInfo: freezed == arrayChunkInfo
            ? _value._arrayChunkInfo
            : arrayChunkInfo // ignore: cast_nullable_to_non_nullable
                  as List<ChunkInfo>?,
        arrayId: freezed == arrayId
            ? _value._arrayId
            : arrayId // ignore: cast_nullable_to_non_nullable
                  as List<int>?,
      ),
    );
  }
}

/// @nodoc

class _$ServiceMessageImpl implements _ServiceMessage {
  const _$ServiceMessageImpl({
    required this.id,
    required this.reason,
    final List<ChunkInfo>? arrayChunkInfo,
    final List<int>? arrayId,
  }) : _arrayChunkInfo = arrayChunkInfo,
       _arrayId = arrayId;

  /// Unique message identifier
  @override
  final int id;

  /// Reason/command code ('c', 's', or 'x')
  @override
  final String reason;

  /// Optional array of chunk information
  final List<ChunkInfo>? _arrayChunkInfo;

  /// Optional array of chunk information
  @override
  List<ChunkInfo>? get arrayChunkInfo {
    final value = _arrayChunkInfo;
    if (value == null) return null;
    if (_arrayChunkInfo is EqualUnmodifiableListView) return _arrayChunkInfo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Optional array of message IDs
  final List<int>? _arrayId;

  /// Optional array of message IDs
  @override
  List<int>? get arrayId {
    final value = _arrayId;
    if (value == null) return null;
    if (_arrayId is EqualUnmodifiableListView) return _arrayId;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ServiceMessage(id: $id, reason: $reason, arrayChunkInfo: $arrayChunkInfo, arrayId: $arrayId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            const DeepCollectionEquality().equals(
              other._arrayChunkInfo,
              _arrayChunkInfo,
            ) &&
            const DeepCollectionEquality().equals(other._arrayId, _arrayId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    reason,
    const DeepCollectionEquality().hash(_arrayChunkInfo),
    const DeepCollectionEquality().hash(_arrayId),
  );

  /// Create a copy of ServiceMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceMessageImplCopyWith<_$ServiceMessageImpl> get copyWith =>
      __$$ServiceMessageImplCopyWithImpl<_$ServiceMessageImpl>(
        this,
        _$identity,
      );
}

abstract class _ServiceMessage implements ServiceMessage {
  const factory _ServiceMessage({
    required final int id,
    required final String reason,
    final List<ChunkInfo>? arrayChunkInfo,
    final List<int>? arrayId,
  }) = _$ServiceMessageImpl;

  /// Unique message identifier
  @override
  int get id;

  /// Reason/command code ('c', 's', or 'x')
  @override
  String get reason;

  /// Optional array of chunk information
  @override
  List<ChunkInfo>? get arrayChunkInfo;

  /// Optional array of message IDs
  @override
  List<int>? get arrayId;

  /// Create a copy of ServiceMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServiceMessageImplCopyWith<_$ServiceMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MessageType {
  MessageWithId get message => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MessageData message) data,
    required TResult Function(ChunkMessage message) chunk,
    required TResult Function(ServiceMessage message) service,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MessageData message)? data,
    TResult? Function(ChunkMessage message)? chunk,
    TResult? Function(ServiceMessage message)? service,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MessageData message)? data,
    TResult Function(ChunkMessage message)? chunk,
    TResult Function(ServiceMessage message)? service,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageTypeData value) data,
    required TResult Function(MessageTypeChunk value) chunk,
    required TResult Function(MessageTypeService value) service,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageTypeData value)? data,
    TResult? Function(MessageTypeChunk value)? chunk,
    TResult? Function(MessageTypeService value)? service,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageTypeData value)? data,
    TResult Function(MessageTypeChunk value)? chunk,
    TResult Function(MessageTypeService value)? service,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageTypeCopyWith<$Res> {
  factory $MessageTypeCopyWith(
    MessageType value,
    $Res Function(MessageType) then,
  ) = _$MessageTypeCopyWithImpl<$Res, MessageType>;
}

/// @nodoc
class _$MessageTypeCopyWithImpl<$Res, $Val extends MessageType>
    implements $MessageTypeCopyWith<$Res> {
  _$MessageTypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$MessageTypeDataImplCopyWith<$Res> {
  factory _$$MessageTypeDataImplCopyWith(
    _$MessageTypeDataImpl value,
    $Res Function(_$MessageTypeDataImpl) then,
  ) = __$$MessageTypeDataImplCopyWithImpl<$Res>;
  @useResult
  $Res call({MessageData message});

  $MessageDataCopyWith<$Res> get message;
}

/// @nodoc
class __$$MessageTypeDataImplCopyWithImpl<$Res>
    extends _$MessageTypeCopyWithImpl<$Res, _$MessageTypeDataImpl>
    implements _$$MessageTypeDataImplCopyWith<$Res> {
  __$$MessageTypeDataImplCopyWithImpl(
    _$MessageTypeDataImpl _value,
    $Res Function(_$MessageTypeDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$MessageTypeDataImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as MessageData,
      ),
    );
  }

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageDataCopyWith<$Res> get message {
    return $MessageDataCopyWith<$Res>(_value.message, (value) {
      return _then(_value.copyWith(message: value));
    });
  }
}

/// @nodoc

class _$MessageTypeDataImpl implements MessageTypeData {
  const _$MessageTypeDataImpl(this.message);

  @override
  final MessageData message;

  @override
  String toString() {
    return 'MessageType.data(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageTypeDataImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageTypeDataImplCopyWith<_$MessageTypeDataImpl> get copyWith =>
      __$$MessageTypeDataImplCopyWithImpl<_$MessageTypeDataImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MessageData message) data,
    required TResult Function(ChunkMessage message) chunk,
    required TResult Function(ServiceMessage message) service,
  }) {
    return data(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MessageData message)? data,
    TResult? Function(ChunkMessage message)? chunk,
    TResult? Function(ServiceMessage message)? service,
  }) {
    return data?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MessageData message)? data,
    TResult Function(ChunkMessage message)? chunk,
    TResult Function(ServiceMessage message)? service,
    required TResult orElse(),
  }) {
    if (data != null) {
      return data(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageTypeData value) data,
    required TResult Function(MessageTypeChunk value) chunk,
    required TResult Function(MessageTypeService value) service,
  }) {
    return data(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageTypeData value)? data,
    TResult? Function(MessageTypeChunk value)? chunk,
    TResult? Function(MessageTypeService value)? service,
  }) {
    return data?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageTypeData value)? data,
    TResult Function(MessageTypeChunk value)? chunk,
    TResult Function(MessageTypeService value)? service,
    required TResult orElse(),
  }) {
    if (data != null) {
      return data(this);
    }
    return orElse();
  }
}

abstract class MessageTypeData implements MessageType {
  const factory MessageTypeData(final MessageData message) =
      _$MessageTypeDataImpl;

  @override
  MessageData get message;

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageTypeDataImplCopyWith<_$MessageTypeDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessageTypeChunkImplCopyWith<$Res> {
  factory _$$MessageTypeChunkImplCopyWith(
    _$MessageTypeChunkImpl value,
    $Res Function(_$MessageTypeChunkImpl) then,
  ) = __$$MessageTypeChunkImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ChunkMessage message});

  $ChunkMessageCopyWith<$Res> get message;
}

/// @nodoc
class __$$MessageTypeChunkImplCopyWithImpl<$Res>
    extends _$MessageTypeCopyWithImpl<$Res, _$MessageTypeChunkImpl>
    implements _$$MessageTypeChunkImplCopyWith<$Res> {
  __$$MessageTypeChunkImplCopyWithImpl(
    _$MessageTypeChunkImpl _value,
    $Res Function(_$MessageTypeChunkImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$MessageTypeChunkImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as ChunkMessage,
      ),
    );
  }

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChunkMessageCopyWith<$Res> get message {
    return $ChunkMessageCopyWith<$Res>(_value.message, (value) {
      return _then(_value.copyWith(message: value));
    });
  }
}

/// @nodoc

class _$MessageTypeChunkImpl implements MessageTypeChunk {
  const _$MessageTypeChunkImpl(this.message);

  @override
  final ChunkMessage message;

  @override
  String toString() {
    return 'MessageType.chunk(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageTypeChunkImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageTypeChunkImplCopyWith<_$MessageTypeChunkImpl> get copyWith =>
      __$$MessageTypeChunkImplCopyWithImpl<_$MessageTypeChunkImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MessageData message) data,
    required TResult Function(ChunkMessage message) chunk,
    required TResult Function(ServiceMessage message) service,
  }) {
    return chunk(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MessageData message)? data,
    TResult? Function(ChunkMessage message)? chunk,
    TResult? Function(ServiceMessage message)? service,
  }) {
    return chunk?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MessageData message)? data,
    TResult Function(ChunkMessage message)? chunk,
    TResult Function(ServiceMessage message)? service,
    required TResult orElse(),
  }) {
    if (chunk != null) {
      return chunk(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageTypeData value) data,
    required TResult Function(MessageTypeChunk value) chunk,
    required TResult Function(MessageTypeService value) service,
  }) {
    return chunk(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageTypeData value)? data,
    TResult? Function(MessageTypeChunk value)? chunk,
    TResult? Function(MessageTypeService value)? service,
  }) {
    return chunk?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageTypeData value)? data,
    TResult Function(MessageTypeChunk value)? chunk,
    TResult Function(MessageTypeService value)? service,
    required TResult orElse(),
  }) {
    if (chunk != null) {
      return chunk(this);
    }
    return orElse();
  }
}

abstract class MessageTypeChunk implements MessageType {
  const factory MessageTypeChunk(final ChunkMessage message) =
      _$MessageTypeChunkImpl;

  @override
  ChunkMessage get message;

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageTypeChunkImplCopyWith<_$MessageTypeChunkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MessageTypeServiceImplCopyWith<$Res> {
  factory _$$MessageTypeServiceImplCopyWith(
    _$MessageTypeServiceImpl value,
    $Res Function(_$MessageTypeServiceImpl) then,
  ) = __$$MessageTypeServiceImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ServiceMessage message});

  $ServiceMessageCopyWith<$Res> get message;
}

/// @nodoc
class __$$MessageTypeServiceImplCopyWithImpl<$Res>
    extends _$MessageTypeCopyWithImpl<$Res, _$MessageTypeServiceImpl>
    implements _$$MessageTypeServiceImplCopyWith<$Res> {
  __$$MessageTypeServiceImplCopyWithImpl(
    _$MessageTypeServiceImpl _value,
    $Res Function(_$MessageTypeServiceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$MessageTypeServiceImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as ServiceMessage,
      ),
    );
  }

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ServiceMessageCopyWith<$Res> get message {
    return $ServiceMessageCopyWith<$Res>(_value.message, (value) {
      return _then(_value.copyWith(message: value));
    });
  }
}

/// @nodoc

class _$MessageTypeServiceImpl implements MessageTypeService {
  const _$MessageTypeServiceImpl(this.message);

  @override
  final ServiceMessage message;

  @override
  String toString() {
    return 'MessageType.service(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageTypeServiceImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageTypeServiceImplCopyWith<_$MessageTypeServiceImpl> get copyWith =>
      __$$MessageTypeServiceImplCopyWithImpl<_$MessageTypeServiceImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(MessageData message) data,
    required TResult Function(ChunkMessage message) chunk,
    required TResult Function(ServiceMessage message) service,
  }) {
    return service(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(MessageData message)? data,
    TResult? Function(ChunkMessage message)? chunk,
    TResult? Function(ServiceMessage message)? service,
  }) {
    return service?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(MessageData message)? data,
    TResult Function(ChunkMessage message)? chunk,
    TResult Function(ServiceMessage message)? service,
    required TResult orElse(),
  }) {
    if (service != null) {
      return service(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(MessageTypeData value) data,
    required TResult Function(MessageTypeChunk value) chunk,
    required TResult Function(MessageTypeService value) service,
  }) {
    return service(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(MessageTypeData value)? data,
    TResult? Function(MessageTypeChunk value)? chunk,
    TResult? Function(MessageTypeService value)? service,
  }) {
    return service?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(MessageTypeData value)? data,
    TResult Function(MessageTypeChunk value)? chunk,
    TResult Function(MessageTypeService value)? service,
    required TResult orElse(),
  }) {
    if (service != null) {
      return service(this);
    }
    return orElse();
  }
}

abstract class MessageTypeService implements MessageType {
  const factory MessageTypeService(final ServiceMessage message) =
      _$MessageTypeServiceImpl;

  @override
  ServiceMessage get message;

  /// Create a copy of MessageType
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageTypeServiceImplCopyWith<_$MessageTypeServiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$CallbackOnMessageReceived {
  /// Callback for when a message is received
  CallbackOnMessage get callbackOnMessage => throw _privateConstructorUsedError;

  /// Callback for when data arrives
  CallbackOnDataArrived get callbackOnData =>
      throw _privateConstructorUsedError;

  /// Create a copy of CallbackOnMessageReceived
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CallbackOnMessageReceivedCopyWith<CallbackOnMessageReceived> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CallbackOnMessageReceivedCopyWith<$Res> {
  factory $CallbackOnMessageReceivedCopyWith(
    CallbackOnMessageReceived value,
    $Res Function(CallbackOnMessageReceived) then,
  ) = _$CallbackOnMessageReceivedCopyWithImpl<$Res, CallbackOnMessageReceived>;
  @useResult
  $Res call({
    CallbackOnMessage callbackOnMessage,
    CallbackOnDataArrived callbackOnData,
  });
}

/// @nodoc
class _$CallbackOnMessageReceivedCopyWithImpl<
  $Res,
  $Val extends CallbackOnMessageReceived
>
    implements $CallbackOnMessageReceivedCopyWith<$Res> {
  _$CallbackOnMessageReceivedCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CallbackOnMessageReceived
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? callbackOnMessage = null, Object? callbackOnData = null}) {
    return _then(
      _value.copyWith(
            callbackOnMessage: null == callbackOnMessage
                ? _value.callbackOnMessage
                : callbackOnMessage // ignore: cast_nullable_to_non_nullable
                      as CallbackOnMessage,
            callbackOnData: null == callbackOnData
                ? _value.callbackOnData
                : callbackOnData // ignore: cast_nullable_to_non_nullable
                      as CallbackOnDataArrived,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CallbackOnMessageReceivedImplCopyWith<$Res>
    implements $CallbackOnMessageReceivedCopyWith<$Res> {
  factory _$$CallbackOnMessageReceivedImplCopyWith(
    _$CallbackOnMessageReceivedImpl value,
    $Res Function(_$CallbackOnMessageReceivedImpl) then,
  ) = __$$CallbackOnMessageReceivedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    CallbackOnMessage callbackOnMessage,
    CallbackOnDataArrived callbackOnData,
  });
}

/// @nodoc
class __$$CallbackOnMessageReceivedImplCopyWithImpl<$Res>
    extends
        _$CallbackOnMessageReceivedCopyWithImpl<
          $Res,
          _$CallbackOnMessageReceivedImpl
        >
    implements _$$CallbackOnMessageReceivedImplCopyWith<$Res> {
  __$$CallbackOnMessageReceivedImplCopyWithImpl(
    _$CallbackOnMessageReceivedImpl _value,
    $Res Function(_$CallbackOnMessageReceivedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CallbackOnMessageReceived
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? callbackOnMessage = null, Object? callbackOnData = null}) {
    return _then(
      _$CallbackOnMessageReceivedImpl(
        callbackOnMessage: null == callbackOnMessage
            ? _value.callbackOnMessage
            : callbackOnMessage // ignore: cast_nullable_to_non_nullable
                  as CallbackOnMessage,
        callbackOnData: null == callbackOnData
            ? _value.callbackOnData
            : callbackOnData // ignore: cast_nullable_to_non_nullable
                  as CallbackOnDataArrived,
      ),
    );
  }
}

/// @nodoc

class _$CallbackOnMessageReceivedImpl implements _CallbackOnMessageReceived {
  const _$CallbackOnMessageReceivedImpl({
    required this.callbackOnMessage,
    required this.callbackOnData,
  });

  /// Callback for when a message is received
  @override
  final CallbackOnMessage callbackOnMessage;

  /// Callback for when data arrives
  @override
  final CallbackOnDataArrived callbackOnData;

  @override
  String toString() {
    return 'CallbackOnMessageReceived(callbackOnMessage: $callbackOnMessage, callbackOnData: $callbackOnData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CallbackOnMessageReceivedImpl &&
            (identical(other.callbackOnMessage, callbackOnMessage) ||
                other.callbackOnMessage == callbackOnMessage) &&
            (identical(other.callbackOnData, callbackOnData) ||
                other.callbackOnData == callbackOnData));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, callbackOnMessage, callbackOnData);

  /// Create a copy of CallbackOnMessageReceived
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CallbackOnMessageReceivedImplCopyWith<_$CallbackOnMessageReceivedImpl>
  get copyWith =>
      __$$CallbackOnMessageReceivedImplCopyWithImpl<
        _$CallbackOnMessageReceivedImpl
      >(this, _$identity);
}

abstract class _CallbackOnMessageReceived implements CallbackOnMessageReceived {
  const factory _CallbackOnMessageReceived({
    required final CallbackOnMessage callbackOnMessage,
    required final CallbackOnDataArrived callbackOnData,
  }) = _$CallbackOnMessageReceivedImpl;

  /// Callback for when a message is received
  @override
  CallbackOnMessage get callbackOnMessage;

  /// Callback for when data arrives
  @override
  CallbackOnDataArrived get callbackOnData;

  /// Create a copy of CallbackOnMessageReceived
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CallbackOnMessageReceivedImplCopyWith<_$CallbackOnMessageReceivedImpl>
  get copyWith => throw _privateConstructorUsedError;
}
