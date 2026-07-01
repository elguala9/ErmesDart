import 'package:iermes/iermes.dart';
import 'package:work_db/work_db.dart';

import 'ermes_storage_repository.dart';

/// Repository for managing symmetric keys
class ErmesSymmetricKeyRepository
    extends ErmesStorageRepository<StorageSymmetricKeyType>
    implements IErmesSymmetricKeyRepository {
  /// Creates a symmetric-key repository over [db] and the given [collection].
  ErmesSymmetricKeyRepository(
    IWorkDb db, [
    String collection = defaultCollection,
  ]) : super(db, collection, StorageSymmetricKeyType.fromJson);

  /// Default collection name for symmetric keys.
  static const String defaultCollection = 'ermes_symmetric_keys';
}
