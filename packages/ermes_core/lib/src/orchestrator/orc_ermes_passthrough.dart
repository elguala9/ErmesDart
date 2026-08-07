import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:iermes/iermes.dart';

/// Pass-through delegations from [OrcErmes] to its collaborating book service
/// and signaling server. Extracted to keep [OrcErmes] focused on connection
/// orchestration. The host class supplies [bookService] and [signalingServer].
mixin OrcErmesPassthrough implements IOrcErmes<BookData> {
  /// Book service the account methods delegate to.
  IErmesBookService<BookData> get bookService;

  /// Signaling server the signaling methods delegate to.
  IErmesSignalingServer get signalingServer;

  // ---- Book service pass-through -----------------------------------------

  @override
  Future<void> setAccount(AccountInfo<BookData> info) async =>
      bookService.setAccount(info);

  @override
  Future<void> updateAccount(AccountInfo<BookData> info) async =>
      bookService.updateAccount(info);

  @override
  Future<AccountInfo<BookData>> getAccount(IdAccountType account) async =>
      bookService.getAccount(account);

  @override
  Future<PaginationDto<AccountInfo<BookData>, IdAccountType>> getAccountList(
    IdAccountType cursor,
    int limit,
  ) async => bookService.getAccountList(cursor, limit);

  @override
  Future<bool> deleteAccount(IdAccountType account) async =>
      bookService.deleteAccount(account);

  @override
  Future<void> clear() async => bookService.clear();

  @override
  Future<int> numberOfElements() async => bookService.numberOfElements();

  @override
  Future<List<IdAccountType>> listOfIds() async => bookService.listOfIds();

  @override
  Future<ErmesPeerInfo?> getPeerInfo(IdAccountType account) async =>
      bookService.getPeerInfo(account);

  // ---- Signaling server pass-through -------------------------------------

  @override
  Future<IdAccountType> getIdAccount() async => signalingServer.getIdAccount();

  @override
  Future<bool> isSignalingConnected() async => signalingServer.isConnected();

  @override
  Future<void> onSignalingError(void Function(Object err) callback) async =>
      signalingServer.onError(callback);

  @override
  Future<void> onSignalingClose(void Function() callback) async =>
      signalingServer.onClose(callback);
}
