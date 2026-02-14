// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'signaling_types.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SignalData {
  /// SDP type ('offer' or 'answer')
  String get type => throw _privateConstructorUsedError;

  /// SDP content
  String get sdp => throw _privateConstructorUsedError;

  /// Create a copy of SignalData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SignalDataCopyWith<SignalData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SignalDataCopyWith<$Res> {
  factory $SignalDataCopyWith(
    SignalData value,
    $Res Function(SignalData) then,
  ) = _$SignalDataCopyWithImpl<$Res, SignalData>;
  @useResult
  $Res call({String type, String sdp});
}

/// @nodoc
class _$SignalDataCopyWithImpl<$Res, $Val extends SignalData>
    implements $SignalDataCopyWith<$Res> {
  _$SignalDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SignalData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? type = null, Object? sdp = null}) {
    return _then(
      _value.copyWith(
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            sdp: null == sdp
                ? _value.sdp
                : sdp // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SignalDataImplCopyWith<$Res>
    implements $SignalDataCopyWith<$Res> {
  factory _$$SignalDataImplCopyWith(
    _$SignalDataImpl value,
    $Res Function(_$SignalDataImpl) then,
  ) = __$$SignalDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String type, String sdp});
}

/// @nodoc
class __$$SignalDataImplCopyWithImpl<$Res>
    extends _$SignalDataCopyWithImpl<$Res, _$SignalDataImpl>
    implements _$$SignalDataImplCopyWith<$Res> {
  __$$SignalDataImplCopyWithImpl(
    _$SignalDataImpl _value,
    $Res Function(_$SignalDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SignalData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? type = null, Object? sdp = null}) {
    return _then(
      _$SignalDataImpl(
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        sdp: null == sdp
            ? _value.sdp
            : sdp // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SignalDataImpl implements _SignalData {
  const _$SignalDataImpl({required this.type, required this.sdp});

  /// SDP type ('offer' or 'answer')
  @override
  final String type;

  /// SDP content
  @override
  final String sdp;

  @override
  String toString() {
    return 'SignalData(type: $type, sdp: $sdp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SignalDataImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.sdp, sdp) || other.sdp == sdp));
  }

  @override
  int get hashCode => Object.hash(runtimeType, type, sdp);

  /// Create a copy of SignalData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SignalDataImplCopyWith<_$SignalDataImpl> get copyWith =>
      __$$SignalDataImplCopyWithImpl<_$SignalDataImpl>(this, _$identity);
}

abstract class _SignalData implements SignalData {
  const factory _SignalData({
    required final String type,
    required final String sdp,
  }) = _$SignalDataImpl;

  /// SDP type ('offer' or 'answer')
  @override
  String get type;

  /// SDP content
  @override
  String get sdp;

  /// Create a copy of SignalData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SignalDataImplCopyWith<_$SignalDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Signal {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SignalData signalData) data,
    required TResult Function(String signalString) string,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SignalData signalData)? data,
    TResult? Function(String signalString)? string,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SignalData signalData)? data,
    TResult Function(String signalString)? string,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SignalDataType value) data,
    required TResult Function(SignalStringType value) string,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SignalDataType value)? data,
    TResult? Function(SignalStringType value)? string,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SignalDataType value)? data,
    TResult Function(SignalStringType value)? string,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SignalCopyWith<$Res> {
  factory $SignalCopyWith(Signal value, $Res Function(Signal) then) =
      _$SignalCopyWithImpl<$Res, Signal>;
}

/// @nodoc
class _$SignalCopyWithImpl<$Res, $Val extends Signal>
    implements $SignalCopyWith<$Res> {
  _$SignalCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Signal
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SignalDataTypeImplCopyWith<$Res> {
  factory _$$SignalDataTypeImplCopyWith(
    _$SignalDataTypeImpl value,
    $Res Function(_$SignalDataTypeImpl) then,
  ) = __$$SignalDataTypeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({SignalData signalData});

  $SignalDataCopyWith<$Res> get signalData;
}

/// @nodoc
class __$$SignalDataTypeImplCopyWithImpl<$Res>
    extends _$SignalCopyWithImpl<$Res, _$SignalDataTypeImpl>
    implements _$$SignalDataTypeImplCopyWith<$Res> {
  __$$SignalDataTypeImplCopyWithImpl(
    _$SignalDataTypeImpl _value,
    $Res Function(_$SignalDataTypeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Signal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? signalData = null}) {
    return _then(
      _$SignalDataTypeImpl(
        null == signalData
            ? _value.signalData
            : signalData // ignore: cast_nullable_to_non_nullable
                  as SignalData,
      ),
    );
  }

  /// Create a copy of Signal
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SignalDataCopyWith<$Res> get signalData {
    return $SignalDataCopyWith<$Res>(_value.signalData, (value) {
      return _then(_value.copyWith(signalData: value));
    });
  }
}

/// @nodoc

class _$SignalDataTypeImpl implements SignalDataType {
  const _$SignalDataTypeImpl(this.signalData);

  @override
  final SignalData signalData;

  @override
  String toString() {
    return 'Signal.data(signalData: $signalData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SignalDataTypeImpl &&
            (identical(other.signalData, signalData) ||
                other.signalData == signalData));
  }

  @override
  int get hashCode => Object.hash(runtimeType, signalData);

  /// Create a copy of Signal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SignalDataTypeImplCopyWith<_$SignalDataTypeImpl> get copyWith =>
      __$$SignalDataTypeImplCopyWithImpl<_$SignalDataTypeImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SignalData signalData) data,
    required TResult Function(String signalString) string,
  }) {
    return data(signalData);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SignalData signalData)? data,
    TResult? Function(String signalString)? string,
  }) {
    return data?.call(signalData);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SignalData signalData)? data,
    TResult Function(String signalString)? string,
    required TResult orElse(),
  }) {
    if (data != null) {
      return data(signalData);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SignalDataType value) data,
    required TResult Function(SignalStringType value) string,
  }) {
    return data(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SignalDataType value)? data,
    TResult? Function(SignalStringType value)? string,
  }) {
    return data?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SignalDataType value)? data,
    TResult Function(SignalStringType value)? string,
    required TResult orElse(),
  }) {
    if (data != null) {
      return data(this);
    }
    return orElse();
  }
}

abstract class SignalDataType implements Signal {
  const factory SignalDataType(final SignalData signalData) =
      _$SignalDataTypeImpl;

  SignalData get signalData;

  /// Create a copy of Signal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SignalDataTypeImplCopyWith<_$SignalDataTypeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SignalStringTypeImplCopyWith<$Res> {
  factory _$$SignalStringTypeImplCopyWith(
    _$SignalStringTypeImpl value,
    $Res Function(_$SignalStringTypeImpl) then,
  ) = __$$SignalStringTypeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String signalString});
}

/// @nodoc
class __$$SignalStringTypeImplCopyWithImpl<$Res>
    extends _$SignalCopyWithImpl<$Res, _$SignalStringTypeImpl>
    implements _$$SignalStringTypeImplCopyWith<$Res> {
  __$$SignalStringTypeImplCopyWithImpl(
    _$SignalStringTypeImpl _value,
    $Res Function(_$SignalStringTypeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Signal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? signalString = null}) {
    return _then(
      _$SignalStringTypeImpl(
        null == signalString
            ? _value.signalString
            : signalString // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SignalStringTypeImpl implements SignalStringType {
  const _$SignalStringTypeImpl(this.signalString);

  @override
  final String signalString;

  @override
  String toString() {
    return 'Signal.string(signalString: $signalString)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SignalStringTypeImpl &&
            (identical(other.signalString, signalString) ||
                other.signalString == signalString));
  }

  @override
  int get hashCode => Object.hash(runtimeType, signalString);

  /// Create a copy of Signal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SignalStringTypeImplCopyWith<_$SignalStringTypeImpl> get copyWith =>
      __$$SignalStringTypeImplCopyWithImpl<_$SignalStringTypeImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SignalData signalData) data,
    required TResult Function(String signalString) string,
  }) {
    return string(signalString);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SignalData signalData)? data,
    TResult? Function(String signalString)? string,
  }) {
    return string?.call(signalString);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SignalData signalData)? data,
    TResult Function(String signalString)? string,
    required TResult orElse(),
  }) {
    if (string != null) {
      return string(signalString);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SignalDataType value) data,
    required TResult Function(SignalStringType value) string,
  }) {
    return string(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SignalDataType value)? data,
    TResult? Function(SignalStringType value)? string,
  }) {
    return string?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SignalDataType value)? data,
    TResult Function(SignalStringType value)? string,
    required TResult orElse(),
  }) {
    if (string != null) {
      return string(this);
    }
    return orElse();
  }
}

abstract class SignalStringType implements Signal {
  const factory SignalStringType(final String signalString) =
      _$SignalStringTypeImpl;

  String get signalString;

  /// Create a copy of Signal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SignalStringTypeImplCopyWith<_$SignalStringTypeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ReusableOffer {
  /// SDP content
  String get sdp => throw _privateConstructorUsedError;

  /// Unique identifier for this offer
  String get offerId => throw _privateConstructorUsedError;

  /// Create a copy of ReusableOffer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReusableOfferCopyWith<ReusableOffer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReusableOfferCopyWith<$Res> {
  factory $ReusableOfferCopyWith(
    ReusableOffer value,
    $Res Function(ReusableOffer) then,
  ) = _$ReusableOfferCopyWithImpl<$Res, ReusableOffer>;
  @useResult
  $Res call({String sdp, String offerId});
}

/// @nodoc
class _$ReusableOfferCopyWithImpl<$Res, $Val extends ReusableOffer>
    implements $ReusableOfferCopyWith<$Res> {
  _$ReusableOfferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReusableOffer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? sdp = null, Object? offerId = null}) {
    return _then(
      _value.copyWith(
            sdp: null == sdp
                ? _value.sdp
                : sdp // ignore: cast_nullable_to_non_nullable
                      as String,
            offerId: null == offerId
                ? _value.offerId
                : offerId // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReusableOfferImplCopyWith<$Res>
    implements $ReusableOfferCopyWith<$Res> {
  factory _$$ReusableOfferImplCopyWith(
    _$ReusableOfferImpl value,
    $Res Function(_$ReusableOfferImpl) then,
  ) = __$$ReusableOfferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String sdp, String offerId});
}

/// @nodoc
class __$$ReusableOfferImplCopyWithImpl<$Res>
    extends _$ReusableOfferCopyWithImpl<$Res, _$ReusableOfferImpl>
    implements _$$ReusableOfferImplCopyWith<$Res> {
  __$$ReusableOfferImplCopyWithImpl(
    _$ReusableOfferImpl _value,
    $Res Function(_$ReusableOfferImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReusableOffer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? sdp = null, Object? offerId = null}) {
    return _then(
      _$ReusableOfferImpl(
        sdp: null == sdp
            ? _value.sdp
            : sdp // ignore: cast_nullable_to_non_nullable
                  as String,
        offerId: null == offerId
            ? _value.offerId
            : offerId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ReusableOfferImpl implements _ReusableOffer {
  const _$ReusableOfferImpl({required this.sdp, required this.offerId});

  /// SDP content
  @override
  final String sdp;

  /// Unique identifier for this offer
  @override
  final String offerId;

  @override
  String toString() {
    return 'ReusableOffer(sdp: $sdp, offerId: $offerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReusableOfferImpl &&
            (identical(other.sdp, sdp) || other.sdp == sdp) &&
            (identical(other.offerId, offerId) || other.offerId == offerId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, sdp, offerId);

  /// Create a copy of ReusableOffer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReusableOfferImplCopyWith<_$ReusableOfferImpl> get copyWith =>
      __$$ReusableOfferImplCopyWithImpl<_$ReusableOfferImpl>(this, _$identity);
}

abstract class _ReusableOffer implements ReusableOffer {
  const factory _ReusableOffer({
    required final String sdp,
    required final String offerId,
  }) = _$ReusableOfferImpl;

  /// SDP content
  @override
  String get sdp;

  /// Unique identifier for this offer
  @override
  String get offerId;

  /// Create a copy of ReusableOffer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReusableOfferImplCopyWith<_$ReusableOfferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ReusableAnswer {
  /// Unique identifier for this answer
  String get answerId => throw _privateConstructorUsedError;

  /// Connection identifier
  String get connectionId => throw _privateConstructorUsedError;

  /// ID of the offer this answers
  String get offerId => throw _privateConstructorUsedError;

  /// Target peer identifier
  String get targetPeer => throw _privateConstructorUsedError;

  /// Create a copy of ReusableAnswer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReusableAnswerCopyWith<ReusableAnswer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReusableAnswerCopyWith<$Res> {
  factory $ReusableAnswerCopyWith(
    ReusableAnswer value,
    $Res Function(ReusableAnswer) then,
  ) = _$ReusableAnswerCopyWithImpl<$Res, ReusableAnswer>;
  @useResult
  $Res call({
    String answerId,
    String connectionId,
    String offerId,
    String targetPeer,
  });
}

/// @nodoc
class _$ReusableAnswerCopyWithImpl<$Res, $Val extends ReusableAnswer>
    implements $ReusableAnswerCopyWith<$Res> {
  _$ReusableAnswerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReusableAnswer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? answerId = null,
    Object? connectionId = null,
    Object? offerId = null,
    Object? targetPeer = null,
  }) {
    return _then(
      _value.copyWith(
            answerId: null == answerId
                ? _value.answerId
                : answerId // ignore: cast_nullable_to_non_nullable
                      as String,
            connectionId: null == connectionId
                ? _value.connectionId
                : connectionId // ignore: cast_nullable_to_non_nullable
                      as String,
            offerId: null == offerId
                ? _value.offerId
                : offerId // ignore: cast_nullable_to_non_nullable
                      as String,
            targetPeer: null == targetPeer
                ? _value.targetPeer
                : targetPeer // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReusableAnswerImplCopyWith<$Res>
    implements $ReusableAnswerCopyWith<$Res> {
  factory _$$ReusableAnswerImplCopyWith(
    _$ReusableAnswerImpl value,
    $Res Function(_$ReusableAnswerImpl) then,
  ) = __$$ReusableAnswerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String answerId,
    String connectionId,
    String offerId,
    String targetPeer,
  });
}

/// @nodoc
class __$$ReusableAnswerImplCopyWithImpl<$Res>
    extends _$ReusableAnswerCopyWithImpl<$Res, _$ReusableAnswerImpl>
    implements _$$ReusableAnswerImplCopyWith<$Res> {
  __$$ReusableAnswerImplCopyWithImpl(
    _$ReusableAnswerImpl _value,
    $Res Function(_$ReusableAnswerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReusableAnswer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? answerId = null,
    Object? connectionId = null,
    Object? offerId = null,
    Object? targetPeer = null,
  }) {
    return _then(
      _$ReusableAnswerImpl(
        answerId: null == answerId
            ? _value.answerId
            : answerId // ignore: cast_nullable_to_non_nullable
                  as String,
        connectionId: null == connectionId
            ? _value.connectionId
            : connectionId // ignore: cast_nullable_to_non_nullable
                  as String,
        offerId: null == offerId
            ? _value.offerId
            : offerId // ignore: cast_nullable_to_non_nullable
                  as String,
        targetPeer: null == targetPeer
            ? _value.targetPeer
            : targetPeer // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ReusableAnswerImpl implements _ReusableAnswer {
  const _$ReusableAnswerImpl({
    required this.answerId,
    required this.connectionId,
    required this.offerId,
    required this.targetPeer,
  });

  /// Unique identifier for this answer
  @override
  final String answerId;

  /// Connection identifier
  @override
  final String connectionId;

  /// ID of the offer this answers
  @override
  final String offerId;

  /// Target peer identifier
  @override
  final String targetPeer;

  @override
  String toString() {
    return 'ReusableAnswer(answerId: $answerId, connectionId: $connectionId, offerId: $offerId, targetPeer: $targetPeer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReusableAnswerImpl &&
            (identical(other.answerId, answerId) ||
                other.answerId == answerId) &&
            (identical(other.connectionId, connectionId) ||
                other.connectionId == connectionId) &&
            (identical(other.offerId, offerId) || other.offerId == offerId) &&
            (identical(other.targetPeer, targetPeer) ||
                other.targetPeer == targetPeer));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, answerId, connectionId, offerId, targetPeer);

  /// Create a copy of ReusableAnswer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReusableAnswerImplCopyWith<_$ReusableAnswerImpl> get copyWith =>
      __$$ReusableAnswerImplCopyWithImpl<_$ReusableAnswerImpl>(
        this,
        _$identity,
      );
}

abstract class _ReusableAnswer implements ReusableAnswer {
  const factory _ReusableAnswer({
    required final String answerId,
    required final String connectionId,
    required final String offerId,
    required final String targetPeer,
  }) = _$ReusableAnswerImpl;

  /// Unique identifier for this answer
  @override
  String get answerId;

  /// Connection identifier
  @override
  String get connectionId;

  /// ID of the offer this answers
  @override
  String get offerId;

  /// Target peer identifier
  @override
  String get targetPeer;

  /// Create a copy of ReusableAnswer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReusableAnswerImplCopyWith<_$ReusableAnswerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Response {
  /// Connection identifier
  String get connectionId => throw _privateConstructorUsedError;

  /// Placeholder for peer instance (implementation-specific)
  /// In Dart, you would typically use your peer implementation here
  Object? get peer => throw _privateConstructorUsedError;

  /// Create a copy of Response
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ResponseCopyWith<Response> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResponseCopyWith<$Res> {
  factory $ResponseCopyWith(Response value, $Res Function(Response) then) =
      _$ResponseCopyWithImpl<$Res, Response>;
  @useResult
  $Res call({String connectionId, Object? peer});
}

/// @nodoc
class _$ResponseCopyWithImpl<$Res, $Val extends Response>
    implements $ResponseCopyWith<$Res> {
  _$ResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Response
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? connectionId = null, Object? peer = freezed}) {
    return _then(
      _value.copyWith(
            connectionId: null == connectionId
                ? _value.connectionId
                : connectionId // ignore: cast_nullable_to_non_nullable
                      as String,
            peer: freezed == peer ? _value.peer : peer,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ResponseImplCopyWith<$Res>
    implements $ResponseCopyWith<$Res> {
  factory _$$ResponseImplCopyWith(
    _$ResponseImpl value,
    $Res Function(_$ResponseImpl) then,
  ) = __$$ResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String connectionId, Object? peer});
}

/// @nodoc
class __$$ResponseImplCopyWithImpl<$Res>
    extends _$ResponseCopyWithImpl<$Res, _$ResponseImpl>
    implements _$$ResponseImplCopyWith<$Res> {
  __$$ResponseImplCopyWithImpl(
    _$ResponseImpl _value,
    $Res Function(_$ResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Response
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? connectionId = null, Object? peer = freezed}) {
    return _then(
      _$ResponseImpl(
        connectionId: null == connectionId
            ? _value.connectionId
            : connectionId // ignore: cast_nullable_to_non_nullable
                  as String,
        peer: freezed == peer ? _value.peer : peer,
      ),
    );
  }
}

/// @nodoc

class _$ResponseImpl implements _Response {
  const _$ResponseImpl({required this.connectionId, this.peer});

  /// Connection identifier
  @override
  final String connectionId;

  /// Placeholder for peer instance (implementation-specific)
  /// In Dart, you would typically use your peer implementation here
  @override
  final Object? peer;

  @override
  String toString() {
    return 'Response(connectionId: $connectionId, peer: $peer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ResponseImpl &&
            (identical(other.connectionId, connectionId) ||
                other.connectionId == connectionId) &&
            const DeepCollectionEquality().equals(other.peer, peer));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    connectionId,
    const DeepCollectionEquality().hash(peer),
  );

  /// Create a copy of Response
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ResponseImplCopyWith<_$ResponseImpl> get copyWith =>
      __$$ResponseImplCopyWithImpl<_$ResponseImpl>(this, _$identity);
}

abstract class _Response implements Response {
  const factory _Response({
    required final String connectionId,
    final Object? peer,
  }) = _$ResponseImpl;

  /// Connection identifier
  @override
  String get connectionId;

  /// Placeholder for peer instance (implementation-specific)
  /// In Dart, you would typically use your peer implementation here
  @override
  Object? get peer;

  /// Create a copy of Response
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ResponseImplCopyWith<_$ResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$OfferResponse {
  /// Connection identifier
  String get connectionId => throw _privateConstructorUsedError;

  /// The generated answer signal
  SignalInfoAnswer get answer => throw _privateConstructorUsedError;

  /// Peer instance
  Object? get peer => throw _privateConstructorUsedError;

  /// Create a copy of OfferResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OfferResponseCopyWith<OfferResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OfferResponseCopyWith<$Res> {
  factory $OfferResponseCopyWith(
    OfferResponse value,
    $Res Function(OfferResponse) then,
  ) = _$OfferResponseCopyWithImpl<$Res, OfferResponse>;
  @useResult
  $Res call({String connectionId, SignalInfoAnswer answer, Object? peer});

  $SignalInfoAnswerCopyWith<$Res> get answer;
}

/// @nodoc
class _$OfferResponseCopyWithImpl<$Res, $Val extends OfferResponse>
    implements $OfferResponseCopyWith<$Res> {
  _$OfferResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OfferResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? connectionId = null,
    Object? answer = null,
    Object? peer = freezed,
  }) {
    return _then(
      _value.copyWith(
            connectionId: null == connectionId
                ? _value.connectionId
                : connectionId // ignore: cast_nullable_to_non_nullable
                      as String,
            answer: null == answer
                ? _value.answer
                : answer // ignore: cast_nullable_to_non_nullable
                      as SignalInfoAnswer,
            peer: freezed == peer ? _value.peer : peer,
          )
          as $Val,
    );
  }

  /// Create a copy of OfferResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SignalInfoAnswerCopyWith<$Res> get answer {
    return $SignalInfoAnswerCopyWith<$Res>(_value.answer, (value) {
      return _then(_value.copyWith(answer: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OfferResponseImplCopyWith<$Res>
    implements $OfferResponseCopyWith<$Res> {
  factory _$$OfferResponseImplCopyWith(
    _$OfferResponseImpl value,
    $Res Function(_$OfferResponseImpl) then,
  ) = __$$OfferResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String connectionId, SignalInfoAnswer answer, Object? peer});

  @override
  $SignalInfoAnswerCopyWith<$Res> get answer;
}

/// @nodoc
class __$$OfferResponseImplCopyWithImpl<$Res>
    extends _$OfferResponseCopyWithImpl<$Res, _$OfferResponseImpl>
    implements _$$OfferResponseImplCopyWith<$Res> {
  __$$OfferResponseImplCopyWithImpl(
    _$OfferResponseImpl _value,
    $Res Function(_$OfferResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OfferResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? connectionId = null,
    Object? answer = null,
    Object? peer = freezed,
  }) {
    return _then(
      _$OfferResponseImpl(
        connectionId: null == connectionId
            ? _value.connectionId
            : connectionId // ignore: cast_nullable_to_non_nullable
                  as String,
        answer: null == answer
            ? _value.answer
            : answer // ignore: cast_nullable_to_non_nullable
                  as SignalInfoAnswer,
        peer: freezed == peer ? _value.peer : peer,
      ),
    );
  }
}

/// @nodoc

class _$OfferResponseImpl implements _OfferResponse {
  const _$OfferResponseImpl({
    required this.connectionId,
    required this.answer,
    this.peer,
  });

  /// Connection identifier
  @override
  final String connectionId;

  /// The generated answer signal
  @override
  final SignalInfoAnswer answer;

  /// Peer instance
  @override
  final Object? peer;

  @override
  String toString() {
    return 'OfferResponse(connectionId: $connectionId, answer: $answer, peer: $peer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OfferResponseImpl &&
            (identical(other.connectionId, connectionId) ||
                other.connectionId == connectionId) &&
            (identical(other.answer, answer) || other.answer == answer) &&
            const DeepCollectionEquality().equals(other.peer, peer));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    connectionId,
    answer,
    const DeepCollectionEquality().hash(peer),
  );

  /// Create a copy of OfferResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OfferResponseImplCopyWith<_$OfferResponseImpl> get copyWith =>
      __$$OfferResponseImplCopyWithImpl<_$OfferResponseImpl>(this, _$identity);
}

abstract class _OfferResponse implements OfferResponse {
  const factory _OfferResponse({
    required final String connectionId,
    required final SignalInfoAnswer answer,
    final Object? peer,
  }) = _$OfferResponseImpl;

  /// Connection identifier
  @override
  String get connectionId;

  /// The generated answer signal
  @override
  SignalInfoAnswer get answer;

  /// Peer instance
  @override
  Object? get peer;

  /// Create a copy of OfferResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OfferResponseImplCopyWith<_$OfferResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AnswerResponse {
  /// Connection identifier
  String get connectionId => throw _privateConstructorUsedError;

  /// Remote peer identifier
  String get remotePeerId => throw _privateConstructorUsedError;

  /// Peer instance
  Object? get peer => throw _privateConstructorUsedError;

  /// Create a copy of AnswerResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnswerResponseCopyWith<AnswerResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnswerResponseCopyWith<$Res> {
  factory $AnswerResponseCopyWith(
    AnswerResponse value,
    $Res Function(AnswerResponse) then,
  ) = _$AnswerResponseCopyWithImpl<$Res, AnswerResponse>;
  @useResult
  $Res call({String connectionId, String remotePeerId, Object? peer});
}

/// @nodoc
class _$AnswerResponseCopyWithImpl<$Res, $Val extends AnswerResponse>
    implements $AnswerResponseCopyWith<$Res> {
  _$AnswerResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnswerResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? connectionId = null,
    Object? remotePeerId = null,
    Object? peer = freezed,
  }) {
    return _then(
      _value.copyWith(
            connectionId: null == connectionId
                ? _value.connectionId
                : connectionId // ignore: cast_nullable_to_non_nullable
                      as String,
            remotePeerId: null == remotePeerId
                ? _value.remotePeerId
                : remotePeerId // ignore: cast_nullable_to_non_nullable
                      as String,
            peer: freezed == peer ? _value.peer : peer,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AnswerResponseImplCopyWith<$Res>
    implements $AnswerResponseCopyWith<$Res> {
  factory _$$AnswerResponseImplCopyWith(
    _$AnswerResponseImpl value,
    $Res Function(_$AnswerResponseImpl) then,
  ) = __$$AnswerResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String connectionId, String remotePeerId, Object? peer});
}

/// @nodoc
class __$$AnswerResponseImplCopyWithImpl<$Res>
    extends _$AnswerResponseCopyWithImpl<$Res, _$AnswerResponseImpl>
    implements _$$AnswerResponseImplCopyWith<$Res> {
  __$$AnswerResponseImplCopyWithImpl(
    _$AnswerResponseImpl _value,
    $Res Function(_$AnswerResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AnswerResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? connectionId = null,
    Object? remotePeerId = null,
    Object? peer = freezed,
  }) {
    return _then(
      _$AnswerResponseImpl(
        connectionId: null == connectionId
            ? _value.connectionId
            : connectionId // ignore: cast_nullable_to_non_nullable
                  as String,
        remotePeerId: null == remotePeerId
            ? _value.remotePeerId
            : remotePeerId // ignore: cast_nullable_to_non_nullable
                  as String,
        peer: freezed == peer ? _value.peer : peer,
      ),
    );
  }
}

/// @nodoc

class _$AnswerResponseImpl implements _AnswerResponse {
  const _$AnswerResponseImpl({
    required this.connectionId,
    required this.remotePeerId,
    this.peer,
  });

  /// Connection identifier
  @override
  final String connectionId;

  /// Remote peer identifier
  @override
  final String remotePeerId;

  /// Peer instance
  @override
  final Object? peer;

  @override
  String toString() {
    return 'AnswerResponse(connectionId: $connectionId, remotePeerId: $remotePeerId, peer: $peer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnswerResponseImpl &&
            (identical(other.connectionId, connectionId) ||
                other.connectionId == connectionId) &&
            (identical(other.remotePeerId, remotePeerId) ||
                other.remotePeerId == remotePeerId) &&
            const DeepCollectionEquality().equals(other.peer, peer));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    connectionId,
    remotePeerId,
    const DeepCollectionEquality().hash(peer),
  );

  /// Create a copy of AnswerResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnswerResponseImplCopyWith<_$AnswerResponseImpl> get copyWith =>
      __$$AnswerResponseImplCopyWithImpl<_$AnswerResponseImpl>(
        this,
        _$identity,
      );
}

abstract class _AnswerResponse implements AnswerResponse {
  const factory _AnswerResponse({
    required final String connectionId,
    required final String remotePeerId,
    final Object? peer,
  }) = _$AnswerResponseImpl;

  /// Connection identifier
  @override
  String get connectionId;

  /// Remote peer identifier
  @override
  String get remotePeerId;

  /// Peer instance
  @override
  Object? get peer;

  /// Create a copy of AnswerResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnswerResponseImplCopyWith<_$AnswerResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SignalInfoOffer {
  /// The signal data
  SignalData get signalData => throw _privateConstructorUsedError;

  /// Reusable offer information
  ReusableOffer get reusableOffer => throw _privateConstructorUsedError;

  /// Create a copy of SignalInfoOffer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SignalInfoOfferCopyWith<SignalInfoOffer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SignalInfoOfferCopyWith<$Res> {
  factory $SignalInfoOfferCopyWith(
    SignalInfoOffer value,
    $Res Function(SignalInfoOffer) then,
  ) = _$SignalInfoOfferCopyWithImpl<$Res, SignalInfoOffer>;
  @useResult
  $Res call({SignalData signalData, ReusableOffer reusableOffer});

  $SignalDataCopyWith<$Res> get signalData;
  $ReusableOfferCopyWith<$Res> get reusableOffer;
}

/// @nodoc
class _$SignalInfoOfferCopyWithImpl<$Res, $Val extends SignalInfoOffer>
    implements $SignalInfoOfferCopyWith<$Res> {
  _$SignalInfoOfferCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SignalInfoOffer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? signalData = null, Object? reusableOffer = null}) {
    return _then(
      _value.copyWith(
            signalData: null == signalData
                ? _value.signalData
                : signalData // ignore: cast_nullable_to_non_nullable
                      as SignalData,
            reusableOffer: null == reusableOffer
                ? _value.reusableOffer
                : reusableOffer // ignore: cast_nullable_to_non_nullable
                      as ReusableOffer,
          )
          as $Val,
    );
  }

  /// Create a copy of SignalInfoOffer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SignalDataCopyWith<$Res> get signalData {
    return $SignalDataCopyWith<$Res>(_value.signalData, (value) {
      return _then(_value.copyWith(signalData: value) as $Val);
    });
  }

  /// Create a copy of SignalInfoOffer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReusableOfferCopyWith<$Res> get reusableOffer {
    return $ReusableOfferCopyWith<$Res>(_value.reusableOffer, (value) {
      return _then(_value.copyWith(reusableOffer: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SignalInfoOfferImplCopyWith<$Res>
    implements $SignalInfoOfferCopyWith<$Res> {
  factory _$$SignalInfoOfferImplCopyWith(
    _$SignalInfoOfferImpl value,
    $Res Function(_$SignalInfoOfferImpl) then,
  ) = __$$SignalInfoOfferImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({SignalData signalData, ReusableOffer reusableOffer});

  @override
  $SignalDataCopyWith<$Res> get signalData;
  @override
  $ReusableOfferCopyWith<$Res> get reusableOffer;
}

/// @nodoc
class __$$SignalInfoOfferImplCopyWithImpl<$Res>
    extends _$SignalInfoOfferCopyWithImpl<$Res, _$SignalInfoOfferImpl>
    implements _$$SignalInfoOfferImplCopyWith<$Res> {
  __$$SignalInfoOfferImplCopyWithImpl(
    _$SignalInfoOfferImpl _value,
    $Res Function(_$SignalInfoOfferImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SignalInfoOffer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? signalData = null, Object? reusableOffer = null}) {
    return _then(
      _$SignalInfoOfferImpl(
        signalData: null == signalData
            ? _value.signalData
            : signalData // ignore: cast_nullable_to_non_nullable
                  as SignalData,
        reusableOffer: null == reusableOffer
            ? _value.reusableOffer
            : reusableOffer // ignore: cast_nullable_to_non_nullable
                  as ReusableOffer,
      ),
    );
  }
}

/// @nodoc

class _$SignalInfoOfferImpl extends _SignalInfoOffer {
  const _$SignalInfoOfferImpl({
    required this.signalData,
    required this.reusableOffer,
  }) : super._();

  /// The signal data
  @override
  final SignalData signalData;

  /// Reusable offer information
  @override
  final ReusableOffer reusableOffer;

  @override
  String toString() {
    return 'SignalInfoOffer(signalData: $signalData, reusableOffer: $reusableOffer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SignalInfoOfferImpl &&
            (identical(other.signalData, signalData) ||
                other.signalData == signalData) &&
            (identical(other.reusableOffer, reusableOffer) ||
                other.reusableOffer == reusableOffer));
  }

  @override
  int get hashCode => Object.hash(runtimeType, signalData, reusableOffer);

  /// Create a copy of SignalInfoOffer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SignalInfoOfferImplCopyWith<_$SignalInfoOfferImpl> get copyWith =>
      __$$SignalInfoOfferImplCopyWithImpl<_$SignalInfoOfferImpl>(
        this,
        _$identity,
      );
}

abstract class _SignalInfoOffer extends SignalInfoOffer {
  const factory _SignalInfoOffer({
    required final SignalData signalData,
    required final ReusableOffer reusableOffer,
  }) = _$SignalInfoOfferImpl;
  const _SignalInfoOffer._() : super._();

  /// The signal data
  @override
  SignalData get signalData;

  /// Reusable offer information
  @override
  ReusableOffer get reusableOffer;

  /// Create a copy of SignalInfoOffer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SignalInfoOfferImplCopyWith<_$SignalInfoOfferImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SignalInfoAnswer {
  /// The signal data
  SignalData get signalData => throw _privateConstructorUsedError;

  /// Reusable answer information
  ReusableAnswer get reusableAnswer => throw _privateConstructorUsedError;

  /// Create a copy of SignalInfoAnswer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SignalInfoAnswerCopyWith<SignalInfoAnswer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SignalInfoAnswerCopyWith<$Res> {
  factory $SignalInfoAnswerCopyWith(
    SignalInfoAnswer value,
    $Res Function(SignalInfoAnswer) then,
  ) = _$SignalInfoAnswerCopyWithImpl<$Res, SignalInfoAnswer>;
  @useResult
  $Res call({SignalData signalData, ReusableAnswer reusableAnswer});

  $SignalDataCopyWith<$Res> get signalData;
  $ReusableAnswerCopyWith<$Res> get reusableAnswer;
}

/// @nodoc
class _$SignalInfoAnswerCopyWithImpl<$Res, $Val extends SignalInfoAnswer>
    implements $SignalInfoAnswerCopyWith<$Res> {
  _$SignalInfoAnswerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SignalInfoAnswer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? signalData = null, Object? reusableAnswer = null}) {
    return _then(
      _value.copyWith(
            signalData: null == signalData
                ? _value.signalData
                : signalData // ignore: cast_nullable_to_non_nullable
                      as SignalData,
            reusableAnswer: null == reusableAnswer
                ? _value.reusableAnswer
                : reusableAnswer // ignore: cast_nullable_to_non_nullable
                      as ReusableAnswer,
          )
          as $Val,
    );
  }

  /// Create a copy of SignalInfoAnswer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SignalDataCopyWith<$Res> get signalData {
    return $SignalDataCopyWith<$Res>(_value.signalData, (value) {
      return _then(_value.copyWith(signalData: value) as $Val);
    });
  }

  /// Create a copy of SignalInfoAnswer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReusableAnswerCopyWith<$Res> get reusableAnswer {
    return $ReusableAnswerCopyWith<$Res>(_value.reusableAnswer, (value) {
      return _then(_value.copyWith(reusableAnswer: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SignalInfoAnswerImplCopyWith<$Res>
    implements $SignalInfoAnswerCopyWith<$Res> {
  factory _$$SignalInfoAnswerImplCopyWith(
    _$SignalInfoAnswerImpl value,
    $Res Function(_$SignalInfoAnswerImpl) then,
  ) = __$$SignalInfoAnswerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({SignalData signalData, ReusableAnswer reusableAnswer});

  @override
  $SignalDataCopyWith<$Res> get signalData;
  @override
  $ReusableAnswerCopyWith<$Res> get reusableAnswer;
}

/// @nodoc
class __$$SignalInfoAnswerImplCopyWithImpl<$Res>
    extends _$SignalInfoAnswerCopyWithImpl<$Res, _$SignalInfoAnswerImpl>
    implements _$$SignalInfoAnswerImplCopyWith<$Res> {
  __$$SignalInfoAnswerImplCopyWithImpl(
    _$SignalInfoAnswerImpl _value,
    $Res Function(_$SignalInfoAnswerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SignalInfoAnswer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? signalData = null, Object? reusableAnswer = null}) {
    return _then(
      _$SignalInfoAnswerImpl(
        signalData: null == signalData
            ? _value.signalData
            : signalData // ignore: cast_nullable_to_non_nullable
                  as SignalData,
        reusableAnswer: null == reusableAnswer
            ? _value.reusableAnswer
            : reusableAnswer // ignore: cast_nullable_to_non_nullable
                  as ReusableAnswer,
      ),
    );
  }
}

/// @nodoc

class _$SignalInfoAnswerImpl extends _SignalInfoAnswer {
  const _$SignalInfoAnswerImpl({
    required this.signalData,
    required this.reusableAnswer,
  }) : super._();

  /// The signal data
  @override
  final SignalData signalData;

  /// Reusable answer information
  @override
  final ReusableAnswer reusableAnswer;

  @override
  String toString() {
    return 'SignalInfoAnswer(signalData: $signalData, reusableAnswer: $reusableAnswer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SignalInfoAnswerImpl &&
            (identical(other.signalData, signalData) ||
                other.signalData == signalData) &&
            (identical(other.reusableAnswer, reusableAnswer) ||
                other.reusableAnswer == reusableAnswer));
  }

  @override
  int get hashCode => Object.hash(runtimeType, signalData, reusableAnswer);

  /// Create a copy of SignalInfoAnswer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SignalInfoAnswerImplCopyWith<_$SignalInfoAnswerImpl> get copyWith =>
      __$$SignalInfoAnswerImplCopyWithImpl<_$SignalInfoAnswerImpl>(
        this,
        _$identity,
      );
}

abstract class _SignalInfoAnswer extends SignalInfoAnswer {
  const factory _SignalInfoAnswer({
    required final SignalData signalData,
    required final ReusableAnswer reusableAnswer,
  }) = _$SignalInfoAnswerImpl;
  const _SignalInfoAnswer._() : super._();

  /// The signal data
  @override
  SignalData get signalData;

  /// Reusable answer information
  @override
  ReusableAnswer get reusableAnswer;

  /// Create a copy of SignalInfoAnswer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SignalInfoAnswerImplCopyWith<_$SignalInfoAnswerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SignalInfo {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SignalInfoOffer offer) offer,
    required TResult Function(SignalInfoAnswer answer) answer,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SignalInfoOffer offer)? offer,
    TResult? Function(SignalInfoAnswer answer)? answer,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SignalInfoOffer offer)? offer,
    TResult Function(SignalInfoAnswer answer)? answer,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SignalInfoOfferType value) offer,
    required TResult Function(SignalInfoAnswerType value) answer,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SignalInfoOfferType value)? offer,
    TResult? Function(SignalInfoAnswerType value)? answer,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SignalInfoOfferType value)? offer,
    TResult Function(SignalInfoAnswerType value)? answer,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SignalInfoCopyWith<$Res> {
  factory $SignalInfoCopyWith(
    SignalInfo value,
    $Res Function(SignalInfo) then,
  ) = _$SignalInfoCopyWithImpl<$Res, SignalInfo>;
}

/// @nodoc
class _$SignalInfoCopyWithImpl<$Res, $Val extends SignalInfo>
    implements $SignalInfoCopyWith<$Res> {
  _$SignalInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SignalInfo
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SignalInfoOfferTypeImplCopyWith<$Res> {
  factory _$$SignalInfoOfferTypeImplCopyWith(
    _$SignalInfoOfferTypeImpl value,
    $Res Function(_$SignalInfoOfferTypeImpl) then,
  ) = __$$SignalInfoOfferTypeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({SignalInfoOffer offer});

  $SignalInfoOfferCopyWith<$Res> get offer;
}

/// @nodoc
class __$$SignalInfoOfferTypeImplCopyWithImpl<$Res>
    extends _$SignalInfoCopyWithImpl<$Res, _$SignalInfoOfferTypeImpl>
    implements _$$SignalInfoOfferTypeImplCopyWith<$Res> {
  __$$SignalInfoOfferTypeImplCopyWithImpl(
    _$SignalInfoOfferTypeImpl _value,
    $Res Function(_$SignalInfoOfferTypeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SignalInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? offer = null}) {
    return _then(
      _$SignalInfoOfferTypeImpl(
        null == offer
            ? _value.offer
            : offer // ignore: cast_nullable_to_non_nullable
                  as SignalInfoOffer,
      ),
    );
  }

  /// Create a copy of SignalInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SignalInfoOfferCopyWith<$Res> get offer {
    return $SignalInfoOfferCopyWith<$Res>(_value.offer, (value) {
      return _then(_value.copyWith(offer: value));
    });
  }
}

/// @nodoc

class _$SignalInfoOfferTypeImpl implements SignalInfoOfferType {
  const _$SignalInfoOfferTypeImpl(this.offer);

  @override
  final SignalInfoOffer offer;

  @override
  String toString() {
    return 'SignalInfo.offer(offer: $offer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SignalInfoOfferTypeImpl &&
            (identical(other.offer, offer) || other.offer == offer));
  }

  @override
  int get hashCode => Object.hash(runtimeType, offer);

  /// Create a copy of SignalInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SignalInfoOfferTypeImplCopyWith<_$SignalInfoOfferTypeImpl> get copyWith =>
      __$$SignalInfoOfferTypeImplCopyWithImpl<_$SignalInfoOfferTypeImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SignalInfoOffer offer) offer,
    required TResult Function(SignalInfoAnswer answer) answer,
  }) {
    return offer(this.offer);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SignalInfoOffer offer)? offer,
    TResult? Function(SignalInfoAnswer answer)? answer,
  }) {
    return offer?.call(this.offer);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SignalInfoOffer offer)? offer,
    TResult Function(SignalInfoAnswer answer)? answer,
    required TResult orElse(),
  }) {
    if (offer != null) {
      return offer(this.offer);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SignalInfoOfferType value) offer,
    required TResult Function(SignalInfoAnswerType value) answer,
  }) {
    return offer(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SignalInfoOfferType value)? offer,
    TResult? Function(SignalInfoAnswerType value)? answer,
  }) {
    return offer?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SignalInfoOfferType value)? offer,
    TResult Function(SignalInfoAnswerType value)? answer,
    required TResult orElse(),
  }) {
    if (offer != null) {
      return offer(this);
    }
    return orElse();
  }
}

abstract class SignalInfoOfferType implements SignalInfo {
  const factory SignalInfoOfferType(final SignalInfoOffer offer) =
      _$SignalInfoOfferTypeImpl;

  SignalInfoOffer get offer;

  /// Create a copy of SignalInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SignalInfoOfferTypeImplCopyWith<_$SignalInfoOfferTypeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SignalInfoAnswerTypeImplCopyWith<$Res> {
  factory _$$SignalInfoAnswerTypeImplCopyWith(
    _$SignalInfoAnswerTypeImpl value,
    $Res Function(_$SignalInfoAnswerTypeImpl) then,
  ) = __$$SignalInfoAnswerTypeImplCopyWithImpl<$Res>;
  @useResult
  $Res call({SignalInfoAnswer answer});

  $SignalInfoAnswerCopyWith<$Res> get answer;
}

/// @nodoc
class __$$SignalInfoAnswerTypeImplCopyWithImpl<$Res>
    extends _$SignalInfoCopyWithImpl<$Res, _$SignalInfoAnswerTypeImpl>
    implements _$$SignalInfoAnswerTypeImplCopyWith<$Res> {
  __$$SignalInfoAnswerTypeImplCopyWithImpl(
    _$SignalInfoAnswerTypeImpl _value,
    $Res Function(_$SignalInfoAnswerTypeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SignalInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? answer = null}) {
    return _then(
      _$SignalInfoAnswerTypeImpl(
        null == answer
            ? _value.answer
            : answer // ignore: cast_nullable_to_non_nullable
                  as SignalInfoAnswer,
      ),
    );
  }

  /// Create a copy of SignalInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SignalInfoAnswerCopyWith<$Res> get answer {
    return $SignalInfoAnswerCopyWith<$Res>(_value.answer, (value) {
      return _then(_value.copyWith(answer: value));
    });
  }
}

/// @nodoc

class _$SignalInfoAnswerTypeImpl implements SignalInfoAnswerType {
  const _$SignalInfoAnswerTypeImpl(this.answer);

  @override
  final SignalInfoAnswer answer;

  @override
  String toString() {
    return 'SignalInfo.answer(answer: $answer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SignalInfoAnswerTypeImpl &&
            (identical(other.answer, answer) || other.answer == answer));
  }

  @override
  int get hashCode => Object.hash(runtimeType, answer);

  /// Create a copy of SignalInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SignalInfoAnswerTypeImplCopyWith<_$SignalInfoAnswerTypeImpl>
  get copyWith =>
      __$$SignalInfoAnswerTypeImplCopyWithImpl<_$SignalInfoAnswerTypeImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(SignalInfoOffer offer) offer,
    required TResult Function(SignalInfoAnswer answer) answer,
  }) {
    return answer(this.answer);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(SignalInfoOffer offer)? offer,
    TResult? Function(SignalInfoAnswer answer)? answer,
  }) {
    return answer?.call(this.answer);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(SignalInfoOffer offer)? offer,
    TResult Function(SignalInfoAnswer answer)? answer,
    required TResult orElse(),
  }) {
    if (answer != null) {
      return answer(this.answer);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SignalInfoOfferType value) offer,
    required TResult Function(SignalInfoAnswerType value) answer,
  }) {
    return answer(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SignalInfoOfferType value)? offer,
    TResult? Function(SignalInfoAnswerType value)? answer,
  }) {
    return answer?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SignalInfoOfferType value)? offer,
    TResult Function(SignalInfoAnswerType value)? answer,
    required TResult orElse(),
  }) {
    if (answer != null) {
      return answer(this);
    }
    return orElse();
  }
}

abstract class SignalInfoAnswerType implements SignalInfo {
  const factory SignalInfoAnswerType(final SignalInfoAnswer answer) =
      _$SignalInfoAnswerTypeImpl;

  SignalInfoAnswer get answer;

  /// Create a copy of SignalInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SignalInfoAnswerTypeImplCopyWith<_$SignalInfoAnswerTypeImpl>
  get copyWith => throw _privateConstructorUsedError;
}
