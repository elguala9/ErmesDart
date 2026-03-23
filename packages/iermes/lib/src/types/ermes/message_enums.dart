
import 'package:stun_shsp/stun_shsp.dart';

/// Enum defining the type of message:
/// - base: Base message
/// - chunk: Chunk message (for large data split into pieces)
/// - service: Service message (control messages)
enum MessageValue {
  /// Base message type
  base,

  /// Chunk message type (for large data)
  chunk,

  /// Service message type (control/metadata)
  service,
}

/// Service reason codes as constants
class ServiceReasons {
  /// Completed
  static const String completed = 'c';

  /// Send again (retry)
  static const String sendAgain = 's';

  /// Closing connection
  static const String closing = 'x';

  /// Is sending a new key to use
  static const String newKey = 'k';

  /// Acknowledge
  static const String acknowledge = 'a';
}

/// Base interface for messages with ID
abstract class MessageWithId {
  /// Unique message identifier
  int get id;
}

/// Interface for Ermes types that can be serialized to JSON
///
/// All root message types (MessageRoot, InternalMessage, etc.) should
/// implement this interface to enable polymorphic serialization via
/// the registry pattern.
// ignore: one_member_abstracts
abstract interface class IErmesSerializable {
  /// Serialize this object to JSON
  Map<String, dynamic> toJson();
}

/// Maximum header size in bytes
const int maxHeader = 81; // 24 bytes for ChunkMessage

/// Peer information for Ermes
class ErmesPeerInfo extends PeerInfo {
  ErmesPeerInfo({required super.address, required super.port, this.id});
  String? id;
}
