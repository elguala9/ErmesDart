import '../../iermes.dart' show ISignalErmes;
import '../types/common/type_aliases.dart';

/// Remembers, per counterpart, the newest signal start time accepted so far.
///
/// RFC section 6.1: a receiver MUST NOT regress to a signal older than one
/// already seen for the same counterpart. Signals are compared on
/// `epochTimestampStartConversation`; an equal start is the same signal.
abstract class IErmesSignalLastSeenStore {
  /// True when [signal] starts before the last one accepted for [peer].
  bool isRegression(IdPeer peer, ISignalErmes signal);

  /// True when [signal] starts strictly after the last one accepted for
  /// [peer], or when nothing was accepted for [peer] yet.
  bool isFresher(IdPeer peer, ISignalErmes signal);

  /// Records [signal] as accepted for [peer]. Never moves the last-seen
  /// start backwards.
  void record(IdPeer peer, ISignalErmes signal);

  /// Forgets every counterpart.
  void clear();
}
