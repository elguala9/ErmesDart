import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../../iermes.dart';

/// Account information container
class AccountInfo<InfoJsonType> {
  /// Creates an account info instance
  const AccountInfo({
    required this.account,
    this.info,
    this.peerInfo,
  });

  /// The account identifier
  final IdAccountType account;

  /// Optional account information
  final InfoJsonType? info;

  /// Optional peer information (retrieved from IErmesBookService)
  final ErmesPeerInfo? peerInfo;
}

/// Private interface for account book operations
abstract class _IErmesBookPrivate<TInfo> {
  /// Set an account in the book
  ///
  /// [info] Info on the account
  void setAccount(AccountInfo<TInfo> info);

  /// Update an account in the book
  ///
  /// [account] The account identifier to update
  /// [info] Partial account information to update (only specified fields
  /// are updated)
  void updateAccount(AccountInfo<TInfo> info);

  /// Get account information from the book
  ///
  /// [account] The account identifier to retrieve
  /// Returns the account information stored in the book
  /// Throws if account not found
  AccountInfo<TInfo> getAccount(IdAccountType account);

  /// Get a paginated list of accounts
  ///
  /// [cursor] The account ID from which to start retrieval
  /// (alphabetically ordered)
  /// [limit] Maximum number of accounts to return
  /// Returns a paginated list of account information
  PaginationDto<AccountInfo<TInfo>, IdAccountType>
  getAccountList(IdAccountType cursor, int limit);

  /// Delete an account from the book
  ///
  /// [account] The account identifier to delete
  /// Returns true if the account was deleted, false if it didn't exist
  bool deleteAccount(IdAccountType account);

  /// Destroy the book and free all resources
  void destroy();

  /// Clear all accounts from the book
  void clear();

  /// Get the number of accounts in the book
  ///
  /// Returns the count of stored accounts
  int numberOfElements();

  /// Get a list of all account IDs
  ///
  /// Returns a list of all stored account identifiers
  List<IdAccountType> listOfIds();

  /// Get peer information for an account
  ///
  /// [account] The account identifier to retrieve peer info for
  /// Returns the peer information if available, null otherwise
  ErmesPeerInfo? getPeerInfo(IdAccountType account);
}

/// Service interface for the account book
///
/// This interface manages a directory of accounts/peers that can be
/// connected to, along with their metadata.
abstract class IErmesBookService<TInfo> implements _IErmesBookPrivate<TInfo> {}

/// Repository interface for the account book
///
/// This interface provides the same account management functionality
/// at the repository layer.
abstract class IErmesBookRepository<TInfo>
    implements _IErmesBookPrivate<TInfo> {}
