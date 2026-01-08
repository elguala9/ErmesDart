import 'package:barrel_files_annotation/barrel_files_annotation.dart';

/// Interfaccia base che evita duplicazione del codice sorgente
/// per le operazioni di storage e caching
@includeInBarrelFile
abstract class IErmesStorageAndCachingReserved<DataJson> {
  /// Salva i dati
  Future<void> store(DataJson data);

  /// Recupera i dati per ID
  Future<DataJson?> retrieve(dynamic id);

  /// Elimina i dati per ID
  ///
  /// Ritorna true se un elemento è stato rimosso, false se non esiste
  Future<bool> delete(dynamic id);

  /// Pulisce tutti i dati
  Future<void> clear();

  /// Ritorna il numero di elementi
  int numberOfElements();

  /// Ritorna la lista di tutti gli ID
  Future<List<dynamic>> listOfIds();

  /// Distrugge il repository
  Future<void> destroy();
}
