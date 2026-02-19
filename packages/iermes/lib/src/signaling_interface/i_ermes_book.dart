import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:shsp_types/shsp_types.dart';

import '../../iermes.dart';
import '../types/ermes_types.dart';

@includeInBarrelFile
/// Account information container
class AccountInfo<InfoJsonType> {
  /// Creates an account info instance
  const AccountInfo({required this.account, this.info, this.peerInfo});

  /// The account identifier
  final IdAccountType account;

  /// Optional account information
  final InfoJsonType? info;
  final ErmesPeerInfo? peerInfo;
}

/// Private interface for account book operations
abstract class _IErmesBookPrivate<InfoJsonType> {
  /// Set an account in the book
  ///
  /// [info] Info on the account
  Future<void> setAccount(AccountInfo<InfoJsonType> info);

  /// Update an account in the book
  ///
  /// [account] The account identifier to update
  /// [info] Partial account information to update (only specified fields
  /// are updated)
  Future<void> updateAccount(AccountInfo<InfoJsonType> info);

  /// Get account information from the book
  ///
  /// [account] The account identifier to retrieve
  /// Returns the account information stored in the book
  Future<AccountInfo<InfoJsonType>> getAccount(IdAccountType account);

  /// Get a paginated list of accounts
  ///
  /// [cursor] The account ID from which to start retrieval
  /// (alphabetically ordered)
  /// [limit] Maximum number of accounts to return
  /// Returns a paginated list of account information
  Future<PaginationDto<AccountInfo<InfoJsonType>, IdAccountType>>
  getAccountList(IdAccountType cursor, int limit);

  /// Delete an account from the book
  ///
  /// [account] The account identifier to delete
  /// Returns true if the account was deleted, false if it didn't exist
  Future<bool> deleteAccount(IdAccountType account);

  /// Destroy the book and free all resources
  Future<void> destroy();

  /// Clear all accounts from the book
  Future<void> clear();

  /// Get the number of accounts in the book
  ///
  /// Returns the count of stored accounts
  int numberOfElements();

  /// Get a list of all account IDs
  ///
  /// Returns a list of all stored account identifiers
  Future<List<IdAccountType>> listOfIds();
}

/// Service interface for the account book
///
/// This interface manages a directory of accounts/peers that can be
/// connected to, along with their metadata.
@includeInBarrelFile
abstract class IErmesBookService<InfoJsonType>
    implements _IErmesBookPrivate<InfoJsonType> {}

/// Repository interface for the account book
///
/// This interface provides the same account management functionality
/// at the repository layer.
@includeInBarrelFile
abstract class IErmesBookRepository<InfoJsonType>
    implements _IErmesBookPrivate<InfoJsonType> {}
