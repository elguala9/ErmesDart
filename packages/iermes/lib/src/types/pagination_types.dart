import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_types.freezed.dart';

/// Generic pagination data transfer object
///
/// This class encapsulates paginated results with cursor-based navigation.
///
/// Type parameters:
/// - [T]: The type of items in the list
/// - [C]: The type of cursor used for pagination
@includeInBarrelFile
@Freezed(toJson: false, fromJson: false)
class PaginationDto<T, C> with _$PaginationDto<T, C> {
  /// Creates a pagination DTO
  const factory PaginationDto({
    /// Current cursor position
    required C cursor,

    /// Number of items per page
    required int pageSize,

    /// Total number of items available
    required int totalItems,

    /// End of file/data flag - true if no more data available
    required bool eof,

    /// List of items in the current page
    required List<T> items,

    /// Cursor for the next page
    required C nextCursor,
  }) = _PaginationDto<T, C>;
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
