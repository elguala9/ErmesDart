import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:signaling_contract_sdk/signaling_contract_extensions.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

import 'ermes_signal_type.dart';

/// Implementation of IErmesSignalingServer using SignalingContract
///
/// This class provides peer discovery and connection establishment
/// using a blockchain-based signaling contract.

class ErmesSignalingServer implements IErmesSignalingServer {
  /// Creates a new signaling server instance
  ///
  /// [contract] The deployed SignalingContract instance configured with
  /// the appropriate credentials for this account
  /// [accountId] The account ID of the current user
  ErmesSignalingServer({
    required SignalingContract contract,
    required IdAccountType accountId,
  }) : _contract = contract,
       _accountId = accountId,
       _isConnected = true;

  final SignalingContract _contract;
  final IdAccountType _accountId;
  bool _isConnected;

  // Callback storage
  final Map<String?, void Function(ISignalErmes data)> _signalCallbacks = {};
  final List<void Function(Object err)> _errorCallbacks = [];
  final List<void Function()> _closeCallbacks = [];

  /// Validates if a string is a valid Ethereum address (40 hex chars,
  /// optionally with 0x prefix)
  bool _isValidEthereumAddress(String address) {
    if (address.isEmpty) {
      return false;
    }

    // Check if it matches the Ethereum address pattern: 0x followed by
    // 40 hex chars or just 40 hex chars without the prefix
    final regex = RegExp(r'^(0x)?[0-9a-fA-F]{40}$');
    return regex.hasMatch(address);
  }

  /// Validate and return Ethereum address as string
  ///
  /// Ensures the address is in valid Ethereum format before use.
  String _toEthereumAddress(IdAccountType accountId) {
    if (!_isValidEthereumAddress(accountId)) {
      throw ArgumentError(
        'Invalid Ethereum address: "$accountId". '
        'Expected a 40-character hex string (optionally prefixed with "0x")',
      );
    }

    // Return address with 0x prefix for compatibility
    if (accountId.startsWith('0x')) {
      return accountId;
    }
    return '0x$accountId';
  }

  @override
  Future<void> destroy() async {
    _isConnected = false;
    _signalCallbacks.clear();
    _errorCallbacks.clear();
    _closeCallbacks.clear();
    _notifyClose();
  }

  @override
  Future<IdAccountType> getIdAccount() async => _accountId;

  @override
  Future<SignalErmes> getSignal(IdAccountType from) async {
    try {
      // Validate and convert peer ID to Ethereum address
      final peerAddress = EthereumAddress.fromHex(_toEthereumAddress(from));

      // Get signal from peer with automatic gzip decompression
      // getSignalCompressed handles: contract call, gzip validation,
      // decompression, String conversion
      final signalString = await _contract.getSignalCompressed(peerAddress);
      return SignalErmes.fromString(signalString);
    } catch (e) {
      _notifyError(e);
      rethrow;
    }
  }

  @override
  Future<void> setSignal(ISignalErmes signal, [IdAccountType? to]) async {
    try {
      // setSignalCompressed handles: string conversion and automatic gzip
      // compression. v2.0.0 no longer distinguishes between offer and answer
      // - each peer writes their own signal. The 'to' parameter is kept for
      // local callback notification but not sent to contract.
      await _contract.setSignalCompressed(signal.toString());

      // Notify local callbacks
      _notifySignal(signal, to);
    } catch (e) {
      _notifyError(e);
      rethrow;
    }
  }

  @override
  void onSignal(
    void Function(ISignalErmes data) callback, [
    IdAccountType? from,
  ]) {
    _signalCallbacks[from] = callback;
  }

  @override
  void onError(void Function(Object err) callback) {
    _errorCallbacks.add(callback);
  }

  @override
  void onClose(void Function() callback) {
    _closeCallbacks.add(callback);
  }

  @override
  Future<void> removeAllListeners() async {
    _signalCallbacks.clear();
    _errorCallbacks.clear();
    _closeCallbacks.clear();
  }

  @override
  Future<bool> isConnected() async => _isConnected;

  /// Notify all registered signal callbacks
  void _notifySignal(ISignalErmes signal, IdAccountType? from) {
    // Notify specific callback if registered
    if (from != null && _signalCallbacks.containsKey(from)) {
      _signalCallbacks[from]?.call(signal);
    }

    // Notify general callback (registered without specific 'from')
    if (_signalCallbacks.containsKey(null)) {
      _signalCallbacks[null]?.call(signal);
    }
  }

  /// Notify all registered error callbacks
  void _notifyError(Object error) {
    for (final callback in _errorCallbacks) {
      callback(error);
    }
  }

  /// Notify all registered close callbacks
  void _notifyClose() {
    for (final callback in _closeCallbacks) {
      callback();
    }
  }
}
