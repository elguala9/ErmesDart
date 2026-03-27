
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'ermes_book_repository.dart';

/// Base class with book service logic.
///
/// Responsabilità:
/// - Service layer sopra ErmesBookRepository
/// - Delegazione metodi a repository
@isSingleton
class ErmesBookServiceBase implements IErmesBookService<BookData> {
  ErmesBookServiceBase();
  
  ErmesBookServiceBase.emptyForDI();
  
  @isInjected
  late IErmesBookRepository<BookData> repository = ErmesBookRepository();

  @override
  void setAccount(AccountInfo<BookData> info) =>
      repository.setAccount(info);

  @override
  void updateAccount(AccountInfo<BookData> info) =>
      repository.updateAccount(info);

  @override
  AccountInfo<BookData> getAccount(String account) =>
      repository.getAccount(account);

  @override
  PaginationDto<AccountInfo<BookData>, String> getAccountList(
    String cursor,
    int limit,
  ) =>
      repository.getAccountList(cursor, limit);

  @override
  bool deleteAccount(String account) =>
      repository.deleteAccount(account);

  @override
  void destroy() => repository.destroy();

  @override
  void clear() => repository.clear();

  @override
  int numberOfElements() => repository.numberOfElements();

  @override
  List<String> listOfIds() => repository.listOfIds();

  @override
  ErmesPeerInfo? getPeerInfo(IdAccountType account) =>
      repository.getPeerInfo(account);
}

/// Singleton service per la gestione contatti.
class ErmesBookService extends ErmesBookServiceBase {
  factory ErmesBookService() => _instance;
  ErmesBookService._();
  static final ErmesBookService _instance = ErmesBookService._();
}
