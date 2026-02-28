
import 'package:iermes/iermes.dart';
import 'package:work_db/work_db.dart';

import '../storage_implementation/ermes_storage_repository.dart';
import '../storage_implementation/ermes_storage_service.dart';

/// Crea un repository di storage con il database e la collection specificati

IErmesStorageRepository<T> createErmesStorageRepository<T extends StorageType>(
  IWorkDb db, {
  String collection = 'ermes_messages',
}) => ErmesStorageRepository<T>(db, collection);

/// Crea un service di storage con il repository specificato

IErmesStorageService<T> createErmesStorageService<T extends StorageType>(
  IErmesStorageRepository<T> repo,
) => ErmesStorageService<T>(repo);
