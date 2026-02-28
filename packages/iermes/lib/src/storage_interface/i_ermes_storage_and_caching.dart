import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../../iermes.dart';

/// Combined interface for storage and caching
///
/// This interface extends the reserved interface with additional operations
/// that are common to both storage and caching but not part of the base
/// contract.
abstract class IErmesStorageAndCaching<DataJson>
    implements IErmesStorageAndCachingReserved<DataJson> {
  /// Flush any pending operations to permanent storage
  ///
  /// This is particularly useful for caching implementations that batch writes.
  Future<void> flush();
}
