import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';

@includeInBarrelFile
abstract class ISignalErmes {
  abstract final String publicKey;
  abstract final String ipv6;
  abstract final String ipv6Port;
  abstract final String ipv4;
  abstract final String ipv4Port;
  abstract final int
  epochTimestampStartConversation; // when the peer will start the conversation
  abstract final int
  secondsIntervalWindow; // the intervals in which the conversation will take place
  abstract final int
  epochTimestampExpireConversation; // when the conversation will expire
  @override
  String toString();
  void fromString(String signalString);
  bool isExpired();
  String get signal;
  set signal(String value);
}

@includeInBarrelFile
abstract class ISignalErmesRaw<EncryptionType> {
  abstract final String signal;
  abstract final bool isEncrypted;
  abstract final EncryptionType? encryptionType;
  @override
  String toString();
  void fromString(String signalErmesRawString);
  ISignalErmes getSignal();
}

/// Interface for a signaling server
///
/// This interface defines how to interact with a signaling server
/// that facilitates peer discovery and connection establishment.
@includeInBarrelFile
abstract class IErmesSignalingServer {
  /// Destroy the signaling server connection
  Future<void> destroy();

  /// Get the unique identifier of the current user
  ///
  /// Returns the account ID
  Future<IdAccountType> getIdAccount();

  /// Retrieve a signal that was sent from another peer
  ///
  /// [from] The account ID of the peer who sent the signal
  /// Returns the signal as a string
  Future<ISignalErmes> getSignal(IdAccountType from);

  /// Send a signal to another peer
  ///
  /// [signal] The signal to send
  /// [to] Optional peer ID. If not specified, the signal is available to all
  /// peers
  Future<void> setSignal(ISignalErmes signal, [IdAccountType? to]);

  /// Register a callback for when a signal is received
  ///
  /// [callback] Function to call when a signal arrives
  /// [from] Optional filter to only receive signals from a specific peer
  void onSignal(
    void Function(ISignalErmes data) callback, [
    IdAccountType? from,
  ]);

  /// Register a callback for errors
  ///
  /// [callback] Function to call when an error occurs
  void onError(void Function(Object err) callback);

  /// Register a callback for when the connection closes
  ///
  /// [callback] Function to call when the connection closes
  void onClose(void Function() callback);

  /// Remove all registered event listeners
  Future<void> removeAllListeners();

  /// Check if connected to the signaling server
  ///
  /// Returns true if the connection is active
  Future<bool> isConnected();
}
