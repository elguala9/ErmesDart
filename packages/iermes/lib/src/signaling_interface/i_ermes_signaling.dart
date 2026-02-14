import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import '../types/ermes_callback.dart';

/// Private interface for signaling operations
abstract class _IErmesSignalingPrivate {
  /// Destroy the signaling instance and free resources
  Future<void> destroy();

  /// Retrieve the active account ID for this instance
  ///
  /// Returns the account identifier
  Future<IdAccountType> getIdAccount();

  /// Check if the signaling server is online
  ///
  /// Returns true if connected to the signaling server
  Future<bool> isConnected();

  /// Send a signal to another peer
  ///
  /// [to] The account ID of the destination peer
  Future<void> sendSignal(IdAccountType to);

  /// Remove all registered event listeners
  void removeAllListeners();
}

/// Repository interface for signaling
///
/// This interface handles receiving and sending peer signaling data
/// at the repository layer.
@includeInBarrelFile
abstract class IErmesSignalingRepository<SignalMessageType>
    implements _IErmesSignalingPrivate {
  /// Register a callback to receive signals from other peers
  ///
  /// [callback] Function to call when a signal is received
  void onSignal(OnSignalCallback<SignalMessageType> callback);

  /// Retrieve the last signal from a specific peer
  ///
  /// [from] The account ID of the peer
  /// Returns the signal message
  Future<SignalMessageType> getSignal(IdAccountType from);

  /// Retrieve the signal of the account owner
  ///
  /// Returns the owner's signal message
  Future<SignalMessageType> getSignalOwner();

  /// Compare two signal messages for equality
  ///
  /// [signal1] First signal to compare
  /// [signal2] Second signal to compare
  /// Returns true if the signals are identical
  bool compareSignalMessage(
    SignalMessageType signal1,
    SignalMessageType signal2,
  );
}

/// Service interface for signaling
///
/// This interface handles signaling operations at the service layer,
/// including automatic socket creation when signals are received.
@includeInBarrelFile
abstract class IErmesSignalingService implements _IErmesSignalingPrivate {
  /// Register a callback to receive signals and create sockets
  ///
  /// When a signal is received from another peer, this callback is invoked
  /// with the peer ID and a service instance for communication.
  ///
  /// [callback] Function to call when a signal is received
  void onSignal(OnSignalCreateSocketCallback callback);
}
