import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:iermes/iermes.dart';
import 'package:work_db/work_db.dart';

import '../storage_implementation/ermes_storage_repository.dart';
import '../storage_implementation/ermes_storage_service.dart';

/// Crea un repository di storage con il database e la collection specificati
@includeInBarrelFile
IErmesStorageRepository<T> createErmesStorageRepository<T extends MessageType>(
  IWorkDb db, {
  String collection = 'ermes_messages',
}) => ErmesStorageRepository<T>(db, collection);

/// Crea un service di storage con il repository specificato
@includeInBarrelFile
IErmesStorageService<T> createErmesStorageService<T extends MessageType>(
  IErmesStorageRepository<T> repo,
) => ErmesStorageService<T>(repo);
