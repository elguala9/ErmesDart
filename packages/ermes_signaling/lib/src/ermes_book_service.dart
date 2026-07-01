
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
  /// Creates a book service backed by a default repository.
  ErmesBookServiceBase();

  /// Creates an empty instance used by the dependency injection framework.
  ErmesBookServiceBase.emptyForDI();

  /// Repository the service delegates all contact operations to.
  @isInjected
  late IErmesBookRepository<BookData> repository = ErmesBookRepository();

  /// Stores a contact account.
  @override
  void setAccount(AccountInfo<BookData> info) =>
      repository.setAccount(info);

  /// Updates an existing contact account.
  @override
  void updateAccount(AccountInfo<BookData> info) =>
      repository.updateAccount(info);

  /// Retrieves a stored contact account.
  @override
  AccountInfo<BookData> getAccount(String account) =>
      repository.getAccount(account);

  /// Returns a paginated slice of stored accounts.
  @override
  PaginationDto<AccountInfo<BookData>, String> getAccountList(
    String cursor,
    int limit,
  ) =>
      repository.getAccountList(cursor, limit);

  /// Removes the given account and reports whether it existed.
  @override
  bool deleteAccount(String account) =>
      repository.deleteAccount(account);

  /// Clears all stored data.
  @override
  void destroy() => repository.destroy();

  /// Clears all stored data.
  @override
  void clear() => repository.clear();

  /// Returns the number of stored book entries.
  @override
  int numberOfElements() => repository.numberOfElements();

  /// Returns the list of all stored peer IDs.
  @override
  List<String> listOfIds() => repository.listOfIds();

  /// Returns the stored peer info for the account, or null if absent.
  @override
  ErmesPeerInfo? getPeerInfo(IdAccountType account) =>
      repository.getPeerInfo(account);
}

/// Singleton service per la gestione contatti.
class ErmesBookService extends ErmesBookServiceBase {
  /// Returns the shared singleton instance.
  factory ErmesBookService() => _instance;

  /// Private constructor enforcing the singleton pattern.
  ErmesBookService._();

  /// The single shared instance of the book service.
  static final ErmesBookService _instance = ErmesBookService._();
}
