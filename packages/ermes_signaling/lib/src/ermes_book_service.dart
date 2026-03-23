
import 'package:iermes/iermes.dart';

import 'ermes_book_repository.dart';

/// Base class with book service logic.
///
/// Responsabilità:
/// - Service layer sopra ErmesBookRepository
/// - Delegazione metodi a repository
class ErmesBookServiceBase implements IErmesBookService<BookData> {
  ErmesBookServiceBase() : _repository = ErmesBookRepository();

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

/// Singleton service per la gestione contatti.
class ErmesBookService extends ErmesBookServiceBase {
  factory ErmesBookService() => _instance;
  ErmesBookService._();
  static final ErmesBookService _instance = ErmesBookService._();
}
