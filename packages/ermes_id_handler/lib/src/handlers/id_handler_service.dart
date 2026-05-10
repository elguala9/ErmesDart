
import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';

import '../../ermes_id_handler.dart';

/// Service for managing ID generation with optional persistent storage
@isSingleton
class IdHandlerService implements IIdHandlerService {
  IdHandlerService();
  /// Creates an IdHandlerService
  ///
  /// [repo] - Repository for ID generation
  /// [storage] - Optional storage service for persisting IDs
  IdHandlerService.fromRepo({
    required this.repo,
    IIdHandlerStorageService? storage,
  }) : storage = storage ?? IdHandlerStorageService();

  @isInjected
  late IIdHandlerRepository repo = IdHandlerRepository();
  @isInjected
  late IIdHandlerStorageService storage = IdHandlerStorageService();

  void _storeNewId(IdType newId) {
    storage.update(newId);
  }

  @override
  int getNewId() {
    final newId = repo.getNewId();
    _storeNewId(newId);
    return newId;
  }

  @override
  void reset() {
    repo.reset();
  }

  @override
  void setCounter(int counter) {
    repo.setCounter(counter);
    _storeNewId(counter);
  }

  @override
  int getCurrent() => repo.getCurrent();
}
