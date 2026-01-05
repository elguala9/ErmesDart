import 'package:ermes_types/ermes_types.dart';

/// Base private interface for Ermes connections
abstract class IErmesPrivate {
  /// Returns true if the connection has been closed
  bool isClosed();

  /// Returns true if the connection is open
  bool isConnected();

  /// Wait for the connection of the peer
  Future<void> waitForConnect([int? timeoutMs]);

  /// Resolve when the connection is closed
  Future<void> waitForClose([int? timeoutMs]);
}

/// Repository implementation of the Ermes protocol
///
/// This interface defines the low-level repository layer that handles
/// raw data transmission over peer connections.
abstract class IErmesRepository implements IErmesPrivate {
  /// Send data over the peer connection
  ///
  /// [data] The serialized data that will be sent over peer connection
  void send(SerializableDataType data);

  /// Register a callback to be called when data arrives
  ///
  /// [callback] Callback that will be called when the data arrives
  void onMessage(CallbackOnDataRepository callback);

  /// Close the connection with the other peer
  ///
  /// [force] If false (default), flush before closing. If true, close
  /// immediately.
  void destroy({bool force = false});
}

/// Service handler of the repository
///
/// This interface defines the high-level service layer that handles
/// message-level communication with features like chunking, reliability, etc.
abstract class IErmesService implements IErmesPrivate {
  /// Register a callback to be called when a message arrives
  ///
  /// [callback] The callback to be called when data arrives
  void onMessage(CallbackOnDataArrived callback);

  /// Register a callback to be called when the service is sending data
  ///
  /// [callback] The callback to be called when sending
  void onDataSending(CallbackOnDataSending callback);

  /// Register a callback to be called when the service has sent data
  ///
  /// Note: This does not confirm the data has been received, only that it
  /// has been sent
  /// [callback] The callback to be called after sending
  void onDataSent(CallbackOnDataSent callback);

  /// Send data over the Ermes service
  ///
  /// [message] The data that will be sent over peer connection
  void send(TypeOfDataExternal message);

  /// Close the connection
  void close();

  /// Change the repository
  ///
  /// This will retain all the information in the service
  /// [repository] New repository that the service is going to use
  void setRepository(IErmesRepository repository);
}
