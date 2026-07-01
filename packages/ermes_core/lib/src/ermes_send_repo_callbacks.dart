import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';

/// Owns the pre-send and post-send callback handlers for [ErmesSendRepo].
class ErmesSendRepoCallbacks {
  /// Registry of listeners invoked before a message is sent.
  final CallbackHandler<MessageType, void> _onMessageSendingHandler =
      CallbackHandler<MessageType, void>();
  /// Registry of listeners invoked after a message has been sent.
  final CallbackHandler<MessageType, void> _onMessageSentHandler =
      CallbackHandler<MessageType, void>();

  /// Notifies all pre-send listeners.
  void notifySending(MessageType message) {
    _onMessageSendingHandler.call(message);
  }

  /// Notifies all post-send listeners.
  void notifySent(MessageType message) {
    _onMessageSentHandler.call(message);
  }

  /// Registers a pre-send listener.
  void addOnSending(CallbackOnMessageSending callback) {
    _onMessageSendingHandler.register(callback);
  }

  /// Unregisters a pre-send listener.
  void removeOnSending(CallbackOnMessageSending callback) {
    _onMessageSendingHandler.unregister(callback);
  }

  /// Removes all pre-send listeners.
  void clearOnSending() {
    _onMessageSendingHandler.clear();
  }

  /// Registers a post-send listener.
  void addOnSent(CallbackOnMessageSent callback) {
    _onMessageSentHandler.register(callback);
  }

  /// Unregisters a post-send listener.
  void removeOnSent(CallbackOnMessageSent callback) {
    _onMessageSentHandler.unregister(callback);
  }

  /// Removes all post-send listeners.
  void clearOnSent() {
    _onMessageSentHandler.clear();
  }
}
