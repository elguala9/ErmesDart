

/// Generic pagination data transfer object
///
/// This class encapsulates paginated results with cursor-based navigation.
///
/// Type parameters:
/// - [T]: The type of items in the list
/// - [C]: The type of cursor used for pagination
class PaginationDto<T, C> {
  /// Creates a pagination DTO
  const PaginationDto({
    /// Current cursor position
    required this.cursor,

    /// Number of items per page
    required this.pageSize,

    /// Total number of items available
    required this.totalItems,

    /// End of file/data flag - true if no more data available
    required this.eof,

    /// List of items in the current page
    required this.items,

    /// Cursor for the next page
    required this.nextCursor,
  });

  /// Current cursor position
  final C cursor;

  /// Number of items per page
  final int pageSize;

  /// Total number of items available
  final int totalItems;

  /// End of file/data flag - true if no more data available
  final bool eof;

  /// List of items in the current page
  final List<T> items;

  /// Cursor for the next page
  final C nextCursor;

  /// Creates a copy of this pagination DTO with specified fields replaced
  PaginationDto<T, C> copyWith({
    C? cursor,
    int? pageSize,
    int? totalItems,
    bool? eof,
    List<T>? items,
    C? nextCursor,
  }) =>
      PaginationDto(
        cursor: cursor ?? this.cursor,
        pageSize: pageSize ?? this.pageSize,
        totalItems: totalItems ?? this.totalItems,
        eof: eof ?? this.eof,
        items: items ?? this.items,
        nextCursor: nextCursor ?? this.nextCursor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginationDto<T, C> &&
          runtimeType == other.runtimeType &&
          cursor == other.cursor &&
          pageSize == other.pageSize &&
          totalItems == other.totalItems &&
          eof == other.eof &&
          items == other.items &&
          nextCursor == other.nextCursor;

  @override
  int get hashCode => Object.hash(
        cursor,
        pageSize,
        totalItems,
        eof,
        items,
        nextCursor,
      );

  @override
  String toString() =>
      'PaginationDto(cursor: $cursor, pageSize: $pageSize, '
      'totalItems: $totalItems, eof: $eof, items: $items, '
      'nextCursor: $nextCursor)';
}

/// Extension methods for PaginationDto
extension PaginationDtoExtensions<T, C> on PaginationDto<T, C> {
  /// Check if there are more pages available
  bool get hasMore => !eof;

  /// Check if this is the first page
  bool get isFirstPage => cursor == nextCursor && items.isEmpty;

  /// Check if this is the last page
  bool get isLastPage => eof;

  /// Get the number of items in the current page
  int get itemCount => items.length;

  /// Check if the current page is empty
  bool get isEmpty => items.isEmpty;

  /// Check if the current page is not empty
  bool get isNotEmpty => items.isNotEmpty;
}
