import '../interfaces/iermes_storage.dart';
import '../storage_implementation/ermes_storage_repository.dart';
import '../storage_implementation/ermes_storage_service.dart';

/// Crea un repository di storage con il database e la collection specificati
IErmesStorageRepository<T> createErmesStorageRepository<T>(
  dynamic db, {
  String collection = "ermes_messages",
}) {
  return ErmesStorageRepository<T>(db, collection);
}

/// Crea un service di storage con il repository specificato
IErmesStorageService<T> createErmesStorageService<T>(
  IErmesStorageRepository<T> repo,
) {
  return ErmesStorageService<T>(repo);
}
