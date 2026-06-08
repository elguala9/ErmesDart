
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
  ErmesBookRepository();
  ErmesBookRepository.emptyForDI();

  final Map<IdPeer, BookData> _books = {};
  final Map<IdPeer, ErmesPeerInfo> _peerInfos = {};
  int _numberOfElements = 0;

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

  @override
  AccountInfo<BookData> getAccount(String account) {
    final book = _retrieveBookSync(account);
    if (book == null) {
      throw SignalingException('Account not found: $account');
    }
    return AccountInfo(account: account, info: book);
  }

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

  @override
  bool deleteAccount(String account) => _deleteBookSync(account);

  @override
  void destroy() {
    _books.clear();
    _peerInfos.clear();
    _numberOfElements = 0;
  }

  @override
  void clear() {
    _books.clear();
    _peerInfos.clear();
    _numberOfElements = 0;
  }

  @override
  int numberOfElements() => _numberOfElements;

  @override
  List<String> listOfIds() => _books.keys.cast<String>().toList();

  @override
  ErmesPeerInfo? getPeerInfo(IdAccountType account) => _peerInfos[account];

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


class BookData {
  BookData({required this.peerId, required this.name, required this.timestamp});
  final IdPeer peerId;
  final String name;
  final int timestamp;
}
