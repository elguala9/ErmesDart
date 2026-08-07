import 'package:iermes/iermes.dart';

/// Registry of signal, error and close callbacks for the signaling server.
class ErmesSignalingServerListeners {
  /// Creates an empty listener registry.
  ErmesSignalingServerListeners();

  /// Signal callbacks keyed by sender; the null key matches any sender.
  final Map<IdAccountType?, void Function(ISignalErmes data)>
      signalCallbacks = {};

  /// Callbacks invoked when an error is reported.
  final List<void Function(Object err)> errorCallbacks = [];

  /// Callbacks invoked when the connection closes.
  final List<void Function()> closeCallbacks = [];

  /// Registers a signal callback for the given sender ([from] may be null).
  void onSignal(
    void Function(ISignalErmes data) callback,
    IdAccountType? from,
  ) {
    signalCallbacks[from] = callback;
  }

  /// Registers an error callback.
  void onError(void Function(Object err) callback) {
    errorCallbacks.add(callback);
  }

  /// Registers a close callback.
  void onClose(void Function() callback) {
    closeCallbacks.add(callback);
  }

  /// Dispatches a signal to the sender-specific and wildcard callbacks.
  void notifySignal(ISignalErmes signal, IdAccountType? from) {
    if (from != null && signalCallbacks.containsKey(from)) {
      signalCallbacks[from]?.call(signal);
    }
    if (signalCallbacks.containsKey(null)) {
      signalCallbacks[null]?.call(signal);
    }
  }

  /// Dispatches an error to all registered error callbacks.
  void notifyError(Object error) {
    for (final callback in errorCallbacks) {
      callback(error);
    }
  }

  /// Dispatches a close event to all registered close callbacks.
  void notifyClose() {
    for (final callback in closeCallbacks) {
      callback();
    }
  }

  /// Removes all registered callbacks.
  void clear() {
    signalCallbacks.clear();
    errorCallbacks.clear();
    closeCallbacks.clear();
  }
}
