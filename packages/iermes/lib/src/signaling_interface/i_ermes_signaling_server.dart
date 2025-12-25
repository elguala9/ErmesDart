import 'i_ermes_signaling.dart';

/// Signal type (string representation of signaling data)
typedef SignalType = String;

/// Interface for a signaling server
///
/// This interface defines how to interact with a signaling server
/// that facilitates WebRTC peer discovery and connection establishment.
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
  Future<SignalType> getSignal(IdAccountType from);

  /// Send a signal to another peer
  ///
  /// [signal] The signal to send
  /// [to] Optional peer ID. If not specified, the signal is available to all
  /// peers
  Future<void> setSignal(SignalType signal, [IdAccountType? to]);

  /// Register a callback for when a signal is received
  ///
  /// [callback] Function to call when a signal arrives
  /// [from] Optional filter to only receive signals from a specific peer
  void onSignal(
    void Function(SignalType data) callback, [
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
