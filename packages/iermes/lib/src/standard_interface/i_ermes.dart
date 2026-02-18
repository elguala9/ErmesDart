import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../../iermes.dart';

/// Base private interface for Ermes connections
abstract class IErmesPrivate {
  /// Returns true if the connection has been closed
  bool isClosed();
  /// Returns true if the connection is closing
  bool isClosing();
  /// Returns true if the connection is open
  bool isOpen();
}

/// Repository implementation of the Ermes protocol
///
/// This interface defines the low-level repository layer that handles
/// raw data transmission over peer connections.
@includeInBarrelFile
abstract class IErmesRepository implements IErmesPrivate {
  /// Send data over the peer connection
  ///
  /// [data] The serialized data that will be sent over peer connection
  void send(SerializableDataType data);

  /// Register a listener to be called when data arrives
  ///
  /// [callback] Callback that will be called when the data arrives
  void addOnMessageDataListener(CallbackOnDataRepository callback);

  /// Remove a specific listener for incoming data
  ///
  /// [callback] The callback to remove
  void removeOnMessageDataListener(CallbackOnDataRepository callback);

  /// Clear all listeners for incoming data
  void clearOnMessageDataListeners();

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
@includeInBarrelFile
abstract class IErmesService implements IErmesPrivate {
  /// Register a listener to be called when a message arrives
  ///
  /// [callback] The callback to be called when data arrives
  void addOnMessageDataListener(CallbackOnDataArrived callback);

  /// Remove a specific listener for incoming messages
  ///
  /// [callback] The callback to remove
  void removeOnMessageDataListener(CallbackOnDataArrived callback);

  /// Clear all listeners for incoming messages
  void clearOnMessageDataListeners();

  /// Register a listener to be called when the service is sending data
  ///
  /// [callback] The callback to be called when sending
  void addOnDataSendingListener(CallbackOnDataSending callback);

  /// Remove a specific listener for pre-send events
  ///
  /// [callback] The callback to remove
  void removeOnDataSendingListener(CallbackOnDataSending callback);

  /// Clear all listeners for pre-send events
  void clearOnDataSendingListeners();

  /// Register a listener to be called when the service has sent data
  ///
  /// Note: This does not confirm the data has been received, only that it
  /// has been sent
  /// [callback] The callback to be called after sending
  void addOnDataSentListener(CallbackOnDataSent callback);

  /// Remove a specific listener for post-send events
  ///
  /// [callback] The callback to remove
  void removeOnDataSentListener(CallbackOnDataSent callback);

  /// Clear all listeners for post-send events
  void clearOnDataSentListeners();

  /// Register a listener to be called when a new key arrives
  ///
  /// [callback] The callback to be called when a new key message arrives
  void addOnNewKeyListener(CallbackOnNewKey callback);

  /// Remove a specific listener for incoming new key messages
  ///
  /// [callback] The callback to remove
  void removeOnNewKeyListener(CallbackOnNewKey callback);

  /// Clear all listeners for incoming new key messages
  void clearOnNewKeyListeners();

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
