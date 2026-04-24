import 'package:iermes/iermes.dart';

import 'ermes_storage_service.dart';

/// Service for managing symmetric keys
class ErmesSymmetricKeyService
    extends ErmesStorageService<StorageSymmetricKeyType>
    implements IErmesSymmetricKeyService {
  ErmesSymmetricKeyService(super.repo);
}
