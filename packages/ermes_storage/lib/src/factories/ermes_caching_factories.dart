import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../caching_implementation/ermes_caching_repository.dart';
import '../caching_implementation/ermes_caching_service.dart';
import '../interfaces/iermes_caching.dart';

/// Crea un repository di caching con la dimensione massima
/// del buffer specificata
@includeInBarrelFile
IErmesCachingRepository<T> createErmesCachingRepository<T>([
  int maxBuffer = 1000,
]) => ErmesCachingRepository<T>(maxBuffer);

/// Crea un service di caching con il repository specificato
/// o ne crea uno di default
@includeInBarrelFile
IErmesCachingService<T> createErmesCachingService<T>([
  IErmesCachingRepository<T>? repo,
  int maxBuffer = 1000,
]) {
  final repository = repo ?? createErmesCachingRepository<T>(maxBuffer);
  return ErmesCachingService<T>(repository);
}
