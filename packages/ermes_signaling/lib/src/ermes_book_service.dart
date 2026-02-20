import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import 'ermes_book_repository.dart';

/// 4️⃣ ErmesBookService - Servizio gestione contatti (singleton)
///
/// Responsabilità:
/// - Service layer sopra ErmesBookRepository
/// - Delegazione metodi a repository
/// - Pattern singleton per uso globale
@includeInBarrelFile
class ErmesBookService implements IErmesBookService {
  static final ErmesBookService _instance = ErmesBookService._();

  /// Factory constructor per ottenere l'istanza singleton
  factory ErmesBookService() => _instance;

  final IErmesBookRepository _repository;

  /// Private constructor per singleton
  ErmesBookService._() : _repository = ErmesBookRepository();

  @override
  Future<void> setAccount(AccountInfo<dynamic> info) =>
      _repository.setAccount(info);

  @override
  Future<void> updateAccount(AccountInfo<dynamic> info) =>
      _repository.updateAccount(info);

  @override
  Future<AccountInfo<dynamic>> getAccount(String account) =>
      _repository.getAccount(account);

  @override
  Future<PaginationDto<AccountInfo<dynamic>, String>> getAccountList(
    String cursor,
    int limit,
  ) =>
      _repository.getAccountList(cursor, limit);

  @override
  Future<bool> deleteAccount(String account) =>
      _repository.deleteAccount(account);

  @override
  Future<void> destroy() => _repository.destroy();

  @override
  Future<void> clear() => _repository.clear();

  @override
  int numberOfElements() => _repository.numberOfElements();

  @override
  Future<List<String>> listOfIds() => _repository.listOfIds();

  @override
  Future<ErmesPeerInfo?> getPeerInfo(IdAccountType account) =>
      _repository.getPeerInfo(account);
}
