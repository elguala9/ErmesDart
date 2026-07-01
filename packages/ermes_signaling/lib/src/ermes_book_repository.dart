
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import 'exceptions.dart';

/// 5️⃣ ErmesBookRepository - Gestione contatti
/// Tradotto da: ErmesBookRepository.ts
///
/// Responsabilità:
/// - CRUD operazioni contatti
/// - Paginazione con cursor
/// - Sanitizzazione ID filesystem-safe
@isSingleton
class ErmesBookRepository implements IErmesBookRepository<BookData> {
  /// Creates an empty in-memory contact book repository.
  ErmesBookRepository();

  /// Creates an empty instance used by the dependency injection framework.
  ErmesBookRepository.emptyForDI();

  /// In-memory store mapping peer IDs to their book entries.
  final Map<IdPeer, BookData> _books = {};

  /// In-memory store mapping peer IDs to their full peer information.
  final Map<IdPeer, ErmesPeerInfo> _peerInfos = {};

  /// Running count of stored book entries.
  int _numberOfElements = 0;

  /// Stores a contact account, persisting peer info and book data when present.
  @override
  void setAccount(AccountInfo<BookData> info) {
    if (info.peerInfo != null) {
      _peerInfos[info.account] = info.peerInfo!;
    }
    if (info.info != null) {
      _storeBookSync(
        BookData(
          peerId: info.account,
          name: info.info!.name,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }

  /// Updates an existing contact account; throws if the account is unknown.
  @override
  void updateAccount(AccountInfo<BookData> info) {
    final existing = _retrieveBookSync(info.account);
    if (existing == null) {
      throw SignalingException('Account not found: ${info.account}');
    }
    final name = info.info?.name;
    _storeBookSync(
      BookData(
        peerId: info.account,
        name: name ?? existing.name,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Retrieves a stored contact account; throws if it does not exist.
  @override
  AccountInfo<BookData> getAccount(String account) {
    final book = _retrieveBookSync(account);
    if (book == null) {
      throw SignalingException('Account not found: $account');
    }
    return AccountInfo(account: account, info: book);
  }

  /// Returns a paginated slice of stored accounts starting from the cursor.
  @override
  PaginationDto<AccountInfo<BookData>, String> getAccountList(
    String cursor,
    int limit,
  ) {
    final allIds = _books.keys.toList();
    final sortedIds = allIds..sort();
    final startIndex =
        cursor.isEmpty ? 0 : sortedIds.indexWhere((id) => id == cursor);
    final validStartIndex = startIndex >= 0 ? startIndex : 0;
    final paginatedIds = sortedIds.skip(validStartIndex);
    final items = <AccountInfo<BookData>>[];
    for (final id in paginatedIds.take(limit > 0 ? limit : 0)) {
      final book = _retrieveBookSync(id);
      if (book != null) {
        items.add(AccountInfo<BookData>(account: id, info: book));
      }
    }
    final hasMore = validStartIndex + limit < sortedIds.length;

    return PaginationDto<AccountInfo<BookData>, String>(
      cursor: cursor,
      pageSize: limit,
      totalItems: sortedIds.length,
      eof: !hasMore,
      items: items,
      nextCursor: hasMore && items.isNotEmpty
          ? '${items.last.account}_next'
          : '',
    );
  }

  /// Removes the given account and reports whether it existed.
  @override
  bool deleteAccount(String account) => _deleteBookSync(account);

  /// Clears all stored data and resets the element counter.
  @override
  void destroy() {
    _books.clear();
    _peerInfos.clear();
    _numberOfElements = 0;
  }

  /// Clears all stored data and resets the element counter.
  @override
  void clear() {
    _books.clear();
    _peerInfos.clear();
    _numberOfElements = 0;
  }

  /// Returns the number of stored book entries.
  @override
  int numberOfElements() => _numberOfElements;

  /// Returns the list of all stored peer IDs.
  @override
  List<String> listOfIds() => _books.keys.cast<String>().toList();

  /// Returns the stored peer info for the account, or null if absent.
  @override
  ErmesPeerInfo? getPeerInfo(IdAccountType account) => _peerInfos[account];

  // Sync versions of helper methods
  /// Stores a book entry and increments the counter when it is new.
  void _storeBookSync(BookData book) {
    if (!_books.containsKey(book.peerId)) {
      _numberOfElements++;
    }
    _books[book.peerId] = book;
  }

  /// Retrieves the book entry for the peer, or null if absent.
  BookData? _retrieveBookSync(IdPeer peerId) => _books[peerId];

  /// Removes the peer's book entry and updates the counter; reports success.
  bool _deleteBookSync(IdPeer peerId) {
    if (_books.containsKey(peerId)) {
      _books.remove(peerId);
      _numberOfElements = (_numberOfElements - 1)
          .clamp(0, double.infinity)
          .toInt();
      return true;
    }
    return false;
  }
}


/// A single contact entry holding a peer's identity, display name and time.
class BookData {
  /// Creates a book entry for the given peer.
  BookData({required this.peerId, required this.name, required this.timestamp});

  /// Identifier of the peer this entry describes.
  final IdPeer peerId;

  /// Human-readable display name of the contact.
  final String name;

  /// Epoch milliseconds of the last update to this entry.
  final int timestamp;
}
