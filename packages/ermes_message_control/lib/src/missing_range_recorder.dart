import 'package:iermes/iermes.dart';

/// Adds every id in the inclusive range [from]..[to] to [missing].
///
/// Returns whether the range was non-empty.
bool recordMissingRange(Set<IdType> missing, IdType from, IdType to) {
  for (var i = from; i <= to; i++) {
    missing.add(i);
  }
  return from <= to;
}
