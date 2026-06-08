import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';

/// Owns the pre-send and post-send callback handlers for [ErmesSendRepo].
class ErmesSendRepoCallbacks {
  final CallbackHandler<MessageType, void> _onMessageSendingHandler =
      CallbackHandler<MessageType, void>();
  final CallbackHandler<MessageType, void> _onMessageSentHandler =
      CallbackHandler<MessageType, void>();

  void notifySending(MessageType message) {
    _onMessageSendingHandler.call(message);
  }

  void notifySent(MessageType message) {
    _onMessageSentHandler.call(message);
  }

  void addOnSending(CallbackOnMessageSending callback) {
    _onMessageSendingHandler.register(callback);
  }

  void removeOnSending(CallbackOnMessageSending callback) {
    _onMessageSendingHandler.unregister(callback);
  }

  void clearOnSending() {
    _onMessageSendingHandler.clear();
  }

  void addOnSent(CallbackOnMessageSent callback) {
    _onMessageSentHandler.register(callback);
  }

  void removeOnSent(CallbackOnMessageSent callback) {
    _onMessageSentHandler.unregister(callback);
  }

  void clearOnSent() {
    _onMessageSentHandler.clear();
  }
}
