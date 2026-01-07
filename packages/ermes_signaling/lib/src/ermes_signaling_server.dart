import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:wallet/wallet.dart';

import 'ermes_signal_type.dart';

/// Implementation of IErmesSignalingServer using SignalingContract
///
/// This class provides peer discovery and connection establishment
/// using a blockchain-based signaling contract.
@includeInBarrelFile
class ErmesSignalingServer implements IErmesSignalingServer {
  /// Creates a new signaling server instance
  ///
  /// [contract] The deployed SignalingContract instance configured with the appropriate credentials for this account
  /// [accountId] The account ID of the current user
  ErmesSignalingServer({
    required SignalingContract contract,
    required IdAccountType accountId,
  })  : _contract = contract,
        _accountId = accountId,
        _isConnected = true;

  final SignalingContract _contract;
  final IdAccountType _accountId;
  bool _isConnected;

  // Callback storage
  final Map<String?, void Function(ISignalType data)> _signalCallbacks = {};
  final List<void Function(Object err)> _errorCallbacks = [];
  final List<void Function()> _closeCallbacks = [];

  /// Validates if a string is a valid Ethereum address (40 hex chars, optionally with 0x prefix)
  bool _isValidEthereumAddress(String address) {
    if (address.isEmpty) return false;

    // Check if it matches the Ethereum address pattern: 0x followed by 40 hex chars
    // or just 40 hex chars without the prefix
    final regex = RegExp(r'^(0x)?[0-9a-fA-F]{40}$');
    return regex.hasMatch(address);
  }

  /// Safely convert IdAccountType to EthereumAddress
  EthereumAddress _toEthereumAddress(IdAccountType accountId) {
    if (!_isValidEthereumAddress(accountId)) {
      throw ArgumentError(
        'Invalid Ethereum address: "$accountId". '
        'Expected a 40-character hex string (optionally prefixed with "0x")',
      );
    }

    return EthereumAddress.fromHex(accountId);
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
  Future<SignalType> getSignal(IdAccountType from) async {
    try {
      // Validate and convert peer ID to Ethereum address
      final peerAddress = _toEthereumAddress(from);

      // Get offer from peer (peer sends us their offer)
      // getOffer returns a tuple (bytes signal, uint256 creationTime)
      final offerTuple = await _contract.getOffer(peerAddress);

      // Extract the signal bytes from the tuple (first element)
      // offerTuple is typically a List where first element is the signal bytes
      late Uint8List signalBytes;
      if (offerTuple is List && offerTuple.isNotEmpty) {
        final firstElement = offerTuple[0];
        if (firstElement is Uint8List) {
          signalBytes = firstElement;
        } else if (firstElement is List<int>) {
          signalBytes = Uint8List.fromList(firstElement);
        } else if (firstElement is List<dynamic>) {
          signalBytes = Uint8List.fromList(
            firstElement.map((e) => e as int).toList(),
          );
        } else {
          throw ArgumentError(
            'Unexpected type for signal: ${firstElement.runtimeType}',
          );
        }
      } else {
        throw ArgumentError(
          'Unexpected return type from getOffer: ${offerTuple.runtimeType}',
        );
      }

      final signalString = String.fromCharCodes(signalBytes);
      return SignalType.fromString(signalString);
    } catch (e) {
      _notifyError(e);
      rethrow;
    }
  }

  @override
  Future<void> setSignal(ISignalType signal, [IdAccountType? to]) async {
    try {
      final signalBytes = Uint8List.fromList(signal.toString().codeUnits);

      if (to != null) {
        // Validate and convert target peer ID to Ethereum address
        final targetAddress = _toEthereumAddress(to);

        // Send answer to specific peer
        await _contract.setAnswer(signalBytes, targetAddress);
      } else {
        // Broadcast offer to all peers
        await _contract.setOffer(signalBytes);
      }

      // Notify local callbacks
      _notifySignal(signal, to);
    } catch (e) {
      _notifyError(e);
      rethrow;
    }
  }

  @override
  void onSignal(
    void Function(ISignalType data) callback, [
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
  void _notifySignal(ISignalType signal, IdAccountType? from) {
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
