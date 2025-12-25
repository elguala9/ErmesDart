import 'package:ermes_types/ermes_types.dart';

import 'i_ermes_storage_reserved.dart';

/// Combined interface for storage and caching
///
/// This interface extends the reserved interface with additional operations
/// that are common to both storage and caching but not part of the base
/// contract.
abstract class IErmesStorageAndCaching<DataJson extends MessageType>
    implements IErmesStorageAndCachingReserved<DataJson> {
  /// Flush any pending operations to permanent storage
  ///
  /// This is particularly useful for caching implementations that batch writes.
  Future<void> flush();
}
