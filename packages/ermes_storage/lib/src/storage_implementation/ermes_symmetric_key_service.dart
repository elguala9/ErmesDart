import 'package:iermes/iermes.dart';

import 'ermes_storage_service.dart';

/// Service for managing symmetric keys
class ErmesSymmetricKeyService
    extends ErmesStorageService<StorageSymmetricKeyType>
    implements IErmesSymmetricKeyService {
  /// Creates a symmetric-key service delegating to the given repository.
  ErmesSymmetricKeyService(super.repo);
}
