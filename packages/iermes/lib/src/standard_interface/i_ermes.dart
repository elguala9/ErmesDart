import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:cryptdart/types/crypto_algorithm.dart';

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

  IdAccountType get remotePeerId;
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

  /// Send a new key exchange message to the peer
  ///
  /// Distributes encryption key material with validity windows
  /// [algorithm] The encryption algorithm being used (e.g., AES)
  /// [key] The hex-encoded key material
  /// [start] Optional start datetime for key validity
  /// [expiration] Optional expiration datetime for key validity
  /// [startMessage] Optional message sequence number to start using this key
  /// [endMessage] Optional message sequence number to stop using this key
  void sendNewKey({
    required CryptoAlgorithm algorithm,
    required String key,
    DateTime? start,
    DateTime? expiration,
    int? startMessage,
    int? endMessage,
  });

  /// Send an acknowledge message to the peer
  ///
  /// Notifies the peer of current ID counter and last received ID information
  void sendAcknowledge();

  /// Start periodic missing message checks
  ///
  /// Sets up a timer that requests missing messages at regular intervals
  /// [intervalMs] Interval in milliseconds between checks
  void startMissingMessagesCheck(int intervalMs);

  /// Stop periodic missing message checks
  ///
  /// Cancels the periodic timer for missing message checks
  void stopMissingMessagesCheck();

  /// Check and request missing messages based on threshold
  ///
  /// This is threshold-based control that requests missing messages
  /// only if the number of missing IDs exceeds the configured threshold
  Future<void> checkAndRequestMissingMessages();

  /// Close the connection
  void close();

  /// Change the repository
  ///
  /// This will retain all the information in the service
  /// [repository] New repository that the service is going to use
  void setRepository(IErmesRepository repository);
}
