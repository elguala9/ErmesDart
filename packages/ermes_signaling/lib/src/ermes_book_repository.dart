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
class ErmesBookRepository implements IErmesBookRepository<String, BookData> {
  final Map<IdPeer, BookData> _books = {};
  int _numberOfElements = 0;

  Future<void> _storeBook(BookData book) async {
    _books[book.peerId] = book;
    if (!_books.containsKey(book.peerId)) {
      _numberOfElements++;
    }
  }

  Future<BookData?> _retrieveBook(IdPeer peerId) async => _books[peerId];

  Future<bool> _deleteBook(IdPeer peerId) async {
    if (_books.containsKey(peerId)) {
      _books.remove(peerId);
      _numberOfElements = (_numberOfElements - 1)
          .clamp(0, double.infinity)
          .toInt();
      return true;
    }
    return false;
  }

  @override
  Future<void> setAccount(String account, [dynamic info]) async {
    if (info != null && info is BookInput) {
      await _storeBook(
        BookData(
          peerId: account,
          name: info.name,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }

  @override
  Future<void> updateAccount(String account, Map<String, dynamic> info) async {
    final existing = await _retrieveBook(account);
    if (existing == null) {
      throw Exception('Account not found: $account');
    }
    final name = info['name'] as String?;
    await _storeBook(
      BookData(
        peerId: account,
        name: name ?? existing.name,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<BookData> getAccount(String account) async {
    final book = await _retrieveBook(account);
    if (book == null) {
      throw Exception('Account not found: $account');
    }
    return book;
  }

  @override
  Future<PaginationDto<AccountInfo<BookData>, String>> getAccountList(
    String cursor,
    int limit,
  ) async {
    final allIds = await Future.value(_books.keys.toList());
    final sortedIds = allIds..sort();
    final startIndex = sortedIds.indexWhere((id) => id == cursor);
    final paginatedIds = sortedIds.skip(
      startIndex > -1 ? startIndex : sortedIds.length,
    );
    final items = <AccountInfo<BookData>>[];
    for (final id in paginatedIds.take(limit)) {
      final book = await _retrieveBook(id);
      if (book != null) {
        items.add(AccountInfo<BookData>(account: id, info: book));
      }
    }
    final hasMore = startIndex + limit < sortedIds.length;

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
  Future<bool> deleteAccount(String account) => _deleteBook(account);

  @override
  Future<void> destroy() async {
    _books.clear();
    _numberOfElements = 0;
  }

  @override
  Future<void> clear() async {
    _books.clear();
    _numberOfElements = 0;
  }

  @override
  int numberOfElements() => _numberOfElements;

  @override
  Future<List<String>> listOfIds() async => _books.keys.cast<String>().toList();
}

@includeInBarrelFile
class BookInput {
  BookInput({required this.name});
  final String name;
}

@includeInBarrelFile
class BookData {
  BookData({required this.peerId, required this.name, required this.timestamp});
  final IdPeer peerId;
  final String name;
  final int timestamp;
}
