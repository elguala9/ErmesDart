import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

/// Selects the most appropriate key from a pool based on validity timestamps.
@includeInBarrelFile
abstract class KeySelector {
  KeySelector._(); // Private constructor to prevent instantiation

  /// Selects the appropriate key for ENCRYPTION based on the current time.
  ///
  /// Selection strategy:
  /// 1. Filters keys that are currently valid (start <= now < expiration)
  /// 2. If valid keys exist, returns the one with the farthest expiration
  /// 3. If no valid keys exist, returns the key with the most recent start
  /// 4. If key list is empty, returns null
  ///
  /// This approach ensures we use current keys when available, and gracefully
  /// handles transitions where the next key may already be distributed.
  static KeyInfo? selectForEncryption(List<KeyInfo> keys, DateTime now) {
    if (keys.isEmpty) {
      return null;
    }

    // Filter currently valid keys
    final validKeys = keys.where(
      (k) => !k.start.isAfter(now) && k.expiration.isAfter(now)
    ).toList();

    if (validKeys.isNotEmpty) {
      // Use the one expiring latest (freshest key)
      validKeys.sort((a, b) => b.expiration.compareTo(a.expiration));
      return validKeys.first;
    }

    // No valid keys: use most recently started (even if future)
    final sortedByStart = [...keys]..sort((a, b) => b.start.compareTo(a.start));
    return sortedByStart.first;
  }

  /// Selects the appropriate key for DECRYPTION based on the current time.
  ///
  /// Selection strategy:
  /// 1. Filters keys that are currently valid (start <= now < expiration)
  /// 2. If valid keys exist, returns the one with the farthest expiration
  /// 3. If no valid keys exist, returns the one with the most recent expiration
  ///    (tolerates clock drift by accepting recently expired keys)
  /// 4. If key list is empty, returns null
  ///
  /// This approach is more tolerant than encryption selection to handle clock
  /// drift between peers and delayed message delivery scenarios.
  static KeyInfo? selectForDecryption(List<KeyInfo> keys, DateTime now) {
    if (keys.isEmpty) {
      return null;
    }

    // Filter currently valid keys
    final validKeys = keys.where(
      (k) => !k.start.isAfter(now) && k.expiration.isAfter(now)
    ).toList();

    if (validKeys.isNotEmpty) {
      // Use the one expiring latest
      validKeys.sort((a, b) => b.expiration.compareTo(a.expiration));
      return validKeys.first;
    }

    // For decryption, try recently expired keys (clock drift tolerance)
    final sortedByExpiration = [...keys]
      ..sort((a, b) => b.expiration.compareTo(a.expiration));
    return sortedByExpiration.first;
  }
}
