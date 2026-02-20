import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

/// 5️⃣ ErmesBookRepository - Gestione contatti
/// Tradotto da: ErmesBookRepository.ts
///
/// Responsabilità:
/// - CRUD operazioni contatti
/// - Paginazione con cursor
/// - Sanitizzazione ID filesystem-safe
@includeInBarrelFile
class ErmesBookRepository implements IErmesBookRepository {
  final Map<IdPeer, BookData> _books = {};
  int _numberOfElements = 0;

  @override
  void setAccount(AccountInfo<dynamic> info) {
    if (info.info != null) {
      _storeBookSync(
        BookData(
          peerId: info.account,
          name: (info.info as BookData).name,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }

  @override
  void updateAccount(AccountInfo<dynamic> info) {
    final existing = _retrieveBookSync(info.account);
    if (existing == null) {
      throw Exception('Account not found: ${info.account}');
    }
    final name = (info.info as BookData?)?.name;
    _storeBookSync(
      BookData(
        peerId: info.account,
        name: name ?? existing.name,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  AccountInfo<dynamic> getAccount(String account) {
    final book = _retrieveBookSync(account);
    if (book == null) {
      throw Exception('Account not found: $account');
    }
    return AccountInfo(account: account, info: book);
  }

  @override
  PaginationDto<AccountInfo<dynamic>, String> getAccountList(
    String cursor,
    int limit,
  ) {
    final allIds = _books.keys.toList();
    final sortedIds = allIds..sort();
    final startIndex = cursor.isEmpty ? 0 : sortedIds.indexWhere((id) => id == cursor);
    final validStartIndex = startIndex >= 0 ? startIndex : 0;
    final paginatedIds = sortedIds.skip(validStartIndex);
    final items = <AccountInfo<dynamic>>[];
    for (final id in paginatedIds.take(limit > 0 ? limit : 0)) {
      final book = _retrieveBookSync(id);
      if (book != null) {
        items.add(AccountInfo<dynamic>(account: id, info: book));
      }
    }
    final hasMore = validStartIndex + limit < sortedIds.length;

    return PaginationDto<AccountInfo<dynamic>, String>(
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

  @override
  bool deleteAccount(String account) => _deleteBookSync(account);

  @override
  void destroy() {
    _books.clear();
    _numberOfElements = 0;
  }

  @override
  void clear() {
    _books.clear();
    _numberOfElements = 0;
  }

  @override
  int numberOfElements() => _numberOfElements;

  @override
  List<String> listOfIds() => _books.keys.cast<String>().toList();

  @override
  ErmesPeerInfo? getPeerInfo(IdAccountType account) {
    // ErmesBookRepository doesn't store peer information
    // Subclasses should override this method if peer info is available
    return null;
  }

  // Sync versions of helper methods
  void _storeBookSync(BookData book) {
    if (!_books.containsKey(book.peerId)) {
      _numberOfElements++;
    }
    _books[book.peerId] = book;
  }

  BookData? _retrieveBookSync(IdPeer peerId) => _books[peerId];

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

@includeInBarrelFile
class BookData {
  BookData({required this.peerId, required this.name, required this.timestamp});
  final IdPeer peerId;
  final String name;
  final int timestamp;
}
