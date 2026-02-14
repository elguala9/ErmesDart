// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pagination_types.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PaginationDto<T, C> {
  /// Current cursor position
  C get cursor => throw _privateConstructorUsedError;

  /// Number of items per page
  int get pageSize => throw _privateConstructorUsedError;

  /// Total number of items available
  int get totalItems => throw _privateConstructorUsedError;

  /// End of file/data flag - true if no more data available
  bool get eof => throw _privateConstructorUsedError;

  /// List of items in the current page
  List<T> get items => throw _privateConstructorUsedError;

  /// Cursor for the next page
  C get nextCursor => throw _privateConstructorUsedError;

  /// Create a copy of PaginationDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaginationDtoCopyWith<T, C, PaginationDto<T, C>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaginationDtoCopyWith<T, C, $Res> {
  factory $PaginationDtoCopyWith(
    PaginationDto<T, C> value,
    $Res Function(PaginationDto<T, C>) then,
  ) = _$PaginationDtoCopyWithImpl<T, C, $Res, PaginationDto<T, C>>;
  @useResult
  $Res call({
    C cursor,
    int pageSize,
    int totalItems,
    bool eof,
    List<T> items,
    C nextCursor,
  });
}

/// @nodoc
class _$PaginationDtoCopyWithImpl<T, C, $Res, $Val extends PaginationDto<T, C>>
    implements $PaginationDtoCopyWith<T, C, $Res> {
  _$PaginationDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaginationDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cursor = freezed,
    Object? pageSize = null,
    Object? totalItems = null,
    Object? eof = null,
    Object? items = null,
    Object? nextCursor = freezed,
  }) {
    return _then(
      _value.copyWith(
            cursor: freezed == cursor
                ? _value.cursor
                : cursor // ignore: cast_nullable_to_non_nullable
                      as C,
            pageSize: null == pageSize
                ? _value.pageSize
                : pageSize // ignore: cast_nullable_to_non_nullable
                      as int,
            totalItems: null == totalItems
                ? _value.totalItems
                : totalItems // ignore: cast_nullable_to_non_nullable
                      as int,
            eof: null == eof
                ? _value.eof
                : eof // ignore: cast_nullable_to_non_nullable
                      as bool,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<T>,
            nextCursor: freezed == nextCursor
                ? _value.nextCursor
                : nextCursor // ignore: cast_nullable_to_non_nullable
                      as C,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PaginationDtoImplCopyWith<T, C, $Res>
    implements $PaginationDtoCopyWith<T, C, $Res> {
  factory _$$PaginationDtoImplCopyWith(
    _$PaginationDtoImpl<T, C> value,
    $Res Function(_$PaginationDtoImpl<T, C>) then,
  ) = __$$PaginationDtoImplCopyWithImpl<T, C, $Res>;
  @override
  @useResult
  $Res call({
    C cursor,
    int pageSize,
    int totalItems,
    bool eof,
    List<T> items,
    C nextCursor,
  });
}

/// @nodoc
class __$$PaginationDtoImplCopyWithImpl<T, C, $Res>
    extends _$PaginationDtoCopyWithImpl<T, C, $Res, _$PaginationDtoImpl<T, C>>
    implements _$$PaginationDtoImplCopyWith<T, C, $Res> {
  __$$PaginationDtoImplCopyWithImpl(
    _$PaginationDtoImpl<T, C> _value,
    $Res Function(_$PaginationDtoImpl<T, C>) _then,
  ) : super(_value, _then);

  /// Create a copy of PaginationDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cursor = freezed,
    Object? pageSize = null,
    Object? totalItems = null,
    Object? eof = null,
    Object? items = null,
    Object? nextCursor = freezed,
  }) {
    return _then(
      _$PaginationDtoImpl<T, C>(
        cursor: freezed == cursor
            ? _value.cursor
            : cursor // ignore: cast_nullable_to_non_nullable
                  as C,
        pageSize: null == pageSize
            ? _value.pageSize
            : pageSize // ignore: cast_nullable_to_non_nullable
                  as int,
        totalItems: null == totalItems
            ? _value.totalItems
            : totalItems // ignore: cast_nullable_to_non_nullable
                  as int,
        eof: null == eof
            ? _value.eof
            : eof // ignore: cast_nullable_to_non_nullable
                  as bool,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<T>,
        nextCursor: freezed == nextCursor
            ? _value.nextCursor
            : nextCursor // ignore: cast_nullable_to_non_nullable
                  as C,
      ),
    );
  }
}

/// @nodoc

class _$PaginationDtoImpl<T, C> implements _PaginationDto<T, C> {
  const _$PaginationDtoImpl({
    required this.cursor,
    required this.pageSize,
    required this.totalItems,
    required this.eof,
    required final List<T> items,
    required this.nextCursor,
  }) : _items = items;

  /// Current cursor position
  @override
  final C cursor;

  /// Number of items per page
  @override
  final int pageSize;

  /// Total number of items available
  @override
  final int totalItems;

  /// End of file/data flag - true if no more data available
  @override
  final bool eof;

  /// List of items in the current page
  final List<T> _items;

  /// List of items in the current page
  @override
  List<T> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  /// Cursor for the next page
  @override
  final C nextCursor;

  @override
  String toString() {
    return 'PaginationDto<$T, $C>(cursor: $cursor, pageSize: $pageSize, totalItems: $totalItems, eof: $eof, items: $items, nextCursor: $nextCursor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaginationDtoImpl<T, C> &&
            const DeepCollectionEquality().equals(other.cursor, cursor) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize) &&
            (identical(other.totalItems, totalItems) ||
                other.totalItems == totalItems) &&
            (identical(other.eof, eof) || other.eof == eof) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality().equals(
              other.nextCursor,
              nextCursor,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(cursor),
    pageSize,
    totalItems,
    eof,
    const DeepCollectionEquality().hash(_items),
    const DeepCollectionEquality().hash(nextCursor),
  );

  /// Create a copy of PaginationDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaginationDtoImplCopyWith<T, C, _$PaginationDtoImpl<T, C>> get copyWith =>
      __$$PaginationDtoImplCopyWithImpl<T, C, _$PaginationDtoImpl<T, C>>(
        this,
        _$identity,
      );
}

abstract class _PaginationDto<T, C> implements PaginationDto<T, C> {
  const factory _PaginationDto({
    required final C cursor,
    required final int pageSize,
    required final int totalItems,
    required final bool eof,
    required final List<T> items,
    required final C nextCursor,
  }) = _$PaginationDtoImpl<T, C>;

  /// Current cursor position
  @override
  C get cursor;

  /// Number of items per page
  @override
  int get pageSize;

  /// Total number of items available
  @override
  int get totalItems;

  /// End of file/data flag - true if no more data available
  @override
  bool get eof;

  /// List of items in the current page
  @override
  List<T> get items;

  /// Cursor for the next page
  @override
  C get nextCursor;

  /// Create a copy of PaginationDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaginationDtoImplCopyWith<T, C, _$PaginationDtoImpl<T, C>> get copyWith =>
      throw _privateConstructorUsedError;
}
