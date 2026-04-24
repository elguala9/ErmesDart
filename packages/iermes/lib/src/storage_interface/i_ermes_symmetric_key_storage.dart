import '../../iermes.dart';

/// Repository interface for symmetric key storage
abstract class IErmesSymmetricKeyRepository
    implements IErmesStorageRepository<StorageSymmetricKeyType> {}

/// Service interface for symmetric key storage
abstract class IErmesSymmetricKeyService
    implements IErmesStorageService<StorageSymmetricKeyType> {}
