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
class ErmesBookService implements IErmesBookService<BookInput, BookData> {
  static final ErmesBookService _instance = ErmesBookService._();

  /// Factory constructor per ottenere l'istanza singleton
  factory ErmesBookService() => _instance;

  final IErmesBookRepository<BookInput, BookData> _repository;

  /// Private constructor per singleton
  ErmesBookService._() : _repository = ErmesBookRepository();

  @override
  Future<void> setAccount(String account, [BookInput? info]) =>
      _repository.setAccount(account, info);

  @override
  Future<void> updateAccount(String account, Map<String, dynamic> info) =>
      _repository.updateAccount(account, info);

  @override
  Future<BookData> getAccount(String account) =>
      _repository.getAccount(account);

  @override
  Future<PaginationDto<AccountInfo<BookData>, String>> getAccountList(
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
}
