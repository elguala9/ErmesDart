import 'package:iermes/iermes.dart';

class ErmesSignalingServerListeners {
  ErmesSignalingServerListeners();

  final Map<IdAccountType?, void Function(ISignalErmes data)>
      signalCallbacks = {};
  final List<void Function(Object err)> errorCallbacks = [];
  final List<void Function()> closeCallbacks = [];

  void onSignal(
    void Function(ISignalErmes data) callback,
    IdAccountType? from,
  ) {
    signalCallbacks[from] = callback;
  }

  void onError(void Function(Object err) callback) {
    errorCallbacks.add(callback);
  }

  void onClose(void Function() callback) {
    closeCallbacks.add(callback);
  }

  void notifySignal(ISignalErmes signal, IdAccountType? from) {
    if (from != null && signalCallbacks.containsKey(from)) {
      signalCallbacks[from]?.call(signal);
    }
    if (signalCallbacks.containsKey(null)) {
      signalCallbacks[null]?.call(signal);
    }
  }

  void notifyError(Object error) {
    for (final callback in errorCallbacks) {
      callback(error);
    }
  }

  void notifyClose() {
    for (final callback in closeCallbacks) {
      callback();
    }
  }

  void clear() {
    signalCallbacks.clear();
    errorCallbacks.clear();
    closeCallbacks.clear();
  }
}
