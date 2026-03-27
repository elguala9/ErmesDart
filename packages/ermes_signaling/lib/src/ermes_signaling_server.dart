import 'dart:async';

import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:signaling_contract_sdk/signaling_contract_extensions.dart';
import 'package:stun_shsp/stun_shsp.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart' show Transaction;

import 'ermes_signal_type.dart';

/// Implementation of IErmesSignalingServer using SignalingContract
///
/// This class provides peer discovery and connection establishment
/// using a blockchain-based signaling contract.
@isSingleton
class ErmesSignalingServer implements IErmesSignalingServer {
  
  /// Creates a new signaling server instance
  ///
  /// [contract] The deployed SignalingContract instance configured with
  /// the appropriate credentials for this account
  /// [accountId] The account ID of the current user
  ErmesSignalingServer({
    required this.contract,
    required this.accountId,
  }) : _isConnected = true;

  ErmesSignalingServer.emptyForDI();
  @isInjected
  late SignalingContract contract;
  @isInjected
  late IdAccountType accountId;
  // used only to satisfy isConnected of the interface 
  ////TODO: probably can be upgraded to try to see if the blockcahin (adn contract  is online)
  bool _isConnected = true;

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
    _notifyClose();
    _signalCallbacks.clear();
    _errorCallbacks.clear();
    _closeCallbacks.clear();
  }

  @override
  Future<IdAccountType> getIdAccount() async => accountId;

  @override
  Future<SignalErmes> getSignal(IdAccountType from) async {
    try {
      // Validate and convert peer ID to Ethereum address
      final peerAddress = EthereumAddress.fromHex(_toEthereumAddress(from));

      // Get signal from peer with automatic gzip decompression
      // getSignalCompressed handles: contract call, gzip validation,
      // decompression, String conversion
      final signalString = await contract.getSignalCompressed(peerAddress);
      return SignalErmes.fromString(signalString);
    } on RangeError catch (e) {
      // web3dart throws RangeError when ABI-decoding empty bytes (no signal set)
      final wrapped = FormatException('No signal found for address: $from', e);
      _notifyError(wrapped);
      throw wrapped;
    } catch (e) {
      _notifyError(e);
      rethrow;
    }
  }

  @override
  Future<void> setSignal(ISignalErmes signal, [IdAccountType? to]) async {
    try {
      // Compress the signal data (gzip) and send directly with a fixed gas
      // limit. The SDK's setSignalCompressed relies on web3dart's estimateGas
      // which can under-estimate for storage overwrites on Ganache, causing
      // silent transaction reverts.
      final compressedData =
          SignalingDataCompression.compressData(signal.toString());
      final function = contract.contract.function('setSignal');
      final transaction = Transaction.callContract(
        contract: contract.contract,
        function: function,
        parameters: [compressedData],
        maxGas: 200000,
      );
      final txHash = await contract.client.sendTransaction(
        contract.credentials!,
        transaction,
        chainId: contract.chainId,
      );

      // Wait for the transaction to be mined before returning.
      // This ensures that getSignal() called immediately after will see
      // the stored signal (avoids race conditions with Ganache auto-mining).
      await _waitForReceipt(txHash);

      // Notify local callbacks
      _notifySignal(signal, to);
    } catch (e) {
      _notifyError(e);
      rethrow;
    }
  }

  /// Polls for a transaction receipt until it's available (tx is mined).
  /// Throws if the transaction was reverted or if no receipt arrives in time.
  Future<void> _waitForReceipt(String txHash) async {
    for (var i = 0; i < 30; i++) {
      final receipt = await contract.client.getTransactionReceipt(txHash);
      if (receipt != null) {
        if (receipt.status == false) {
          throw Exception('Transaction reverted: $txHash');
        }
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    throw TimeoutException(
      'Transaction not mined within timeout: $txHash',
      const Duration(seconds: 6),
    );
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
