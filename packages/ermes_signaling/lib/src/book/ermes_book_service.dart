import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'ermes_book_repository.dart';

/// Base class with book service logic.
///
/// Responsabilità:
/// - Service layer sopra ErmesBookRepository
/// - Delegazione metodi a repository
@dependencyInjectable
class ErmesBookServiceBase implements IErmesBookService<BookData> {
  /// Creates a book service delegating to [repository].
  ErmesBookServiceBase(this.repository);

  factory ErmesBookServiceBase.dependencyInjectionFactory({
    String key = 'default',
    // ignore: avoid_unused_constructor_parameters
    String subkey = 'default',
  }) {
    // GENERATED CODE - DO NOT MODIFY BY HAND
    final repository = RegistryManager.instance
        .getInstance<IErmesBookRepository<BookData>>(
          key: key,
        ); // GENERATED CODE - DO NOT MODIFY BY HAND

    return ErmesBookServiceBase(
      // GENERATED CODE - DO NOT MODIFY BY HAND
      repository, // GENERATED CODE - DO NOT MODIFY BY HAND
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Repository the service delegates all contact operations to.
  final IErmesBookRepository<BookData> repository;

  /// Stores a contact account.
  @override
  void setAccount(AccountInfo<BookData> info) => repository.setAccount(info);

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
  ) => repository.getAccountList(cursor, limit);

  /// Removes the given account and reports whether it existed.
  @override
  bool deleteAccount(String account) => repository.deleteAccount(account);

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

  /// Private constructor enforcing the singleton pattern, backed by its own
  /// in-memory repository.
  ErmesBookService._() : super(ErmesBookRepository());

  /// The single shared instance of the book service.
  static final ErmesBookService _instance = ErmesBookService._();
}
