
import 'package:iermes/iermes.dart';

import 'ermes_book_repository.dart';

/// 4️⃣ ErmesBookService - Servizio gestione contatti (singleton)
///
/// Responsabilità:
/// - Service layer sopra ErmesBookRepository
/// - Delegazione metodi a repository
/// - Pattern singleton per uso globale

class ErmesBookService implements IErmesBookService<BookData> {

  /// Factory constructor per ottenere l'istanza singleton
  factory ErmesBookService() => _instance;

  /// Private constructor per singleton
  ErmesBookService._() : _repository = ErmesBookRepository();
  static final ErmesBookService _instance = ErmesBookService._();

  final IErmesBookRepository<BookData> _repository;

  @override
  void setAccount(AccountInfo<BookData> info) =>
      _repository.setAccount(info);

  @override
  void updateAccount(AccountInfo<BookData> info) =>
      _repository.updateAccount(info);

  @override
  AccountInfo<BookData> getAccount(String account) =>
      _repository.getAccount(account);

  @override
  PaginationDto<AccountInfo<BookData>, String> getAccountList(
    String cursor,
    int limit,
  ) =>
      _repository.getAccountList(cursor, limit);

  @override
  bool deleteAccount(String account) =>
      _repository.deleteAccount(account);

  @override
  void destroy() => _repository.destroy();

  @override
  void clear() => _repository.clear();

  @override
  int numberOfElements() => _repository.numberOfElements();

  @override
  List<String> listOfIds() => _repository.listOfIds();

  @override
  ErmesPeerInfo? getPeerInfo(IdAccountType account) =>
      _repository.getPeerInfo(account);
}
