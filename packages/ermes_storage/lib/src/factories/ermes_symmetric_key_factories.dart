import 'package:iermes/iermes.dart';
import 'package:work_db/work_db.dart';

import '../storage_implementation/ermes_symmetric_key_repository.dart';
import '../storage_implementation/ermes_symmetric_key_service.dart';

/// Creates a repository for managing symmetric keys
IErmesSymmetricKeyRepository createErmesSymmetricKeyRepository(
  IWorkDb db, {
  String collection = ErmesSymmetricKeyRepository.defaultCollection,
}) =>
    ErmesSymmetricKeyRepository(db, collection);

/// Creates a service for managing symmetric keys
IErmesSymmetricKeyService createErmesSymmetricKeyService(
  IErmesSymmetricKeyRepository repo,
) =>
    ErmesSymmetricKeyService(repo);
