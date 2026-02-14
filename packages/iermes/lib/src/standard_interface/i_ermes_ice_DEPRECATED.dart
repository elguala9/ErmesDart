// ignore: file_names
// This file should be renamed to follow lower_case_with_underscores convention
import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import 'i_ermes.dart';

/// Private interface for ICE operations
abstract class _IErmesIcePrivate {
  /// Create the signal (offer/answer) that will be passed to the other peer
  ///
  /// Returns a [Signal] object containing the peer signaling data
  Future<Signal> createSignal();

  /// Create the signal as a string representation
  ///
  /// Returns the signal encoded as a string
  Future<String> createSignalString();

  /// Parse a signal string into SignalData
  ///
  /// [signalString] Signal (offer/answer) from the other peer as a string
  /// Returns parsed [SignalData] object
  SignalData parseSignalString(String signalString);

  /// Set the signal received from the other peer
  ///
  /// [signal] Signal (offer/answer) from the other peer
  void setSignal(Signal signal);

  /// Register a callback for when the connection is established
  ///
  /// [callback] Callback to execute when connected
  void onConnect(void Function() callback);

  /// Register a callback for connection errors
  ///
  /// [callback] Callback to execute when an error occurs
  void onError(void Function(Object err) callback);

  /// Register a callback for when the connection closes
  ///
  /// [callback] Callback to execute when connection closes
  void onClose(void Function() callback);

  /// Register a callback for when a signal is generated
  ///
  /// [callback] Callback to execute when signal data is available
  void onSignal(void Function(SignalData data) callback);
}

/// Extension of Ermes with peer-specific methods
///
/// This interface combines the standard Ermes repository functionality
/// with ICE (Interactive Connectivity Establishment) operations required
/// for peer connections.
@includeInBarrelFile
abstract class IErmesIceRepository
    implements IErmesRepository, _IErmesIcePrivate {}
