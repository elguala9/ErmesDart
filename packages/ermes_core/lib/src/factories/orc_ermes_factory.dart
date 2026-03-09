import 'package:iermes/iermes.dart';
import 'package:shsp_interfaces/shsp_interfaces.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';
import 'package:stun/stun.dart';

import '../orc_ermes.dart';
import 'stun_handler_factory_helper.dart';

/// Factory for creating OrcErmes instances
///
/// This factory provides a convenient way to create OrcErmes orchestrators
/// with minimal configuration.
class OrcErmesFactory {
  /// Private constructor to prevent instantiation
  OrcErmesFactory._();

  /// Creates a new OrcErmes instance from a SignalingContract.
  ///
  /// This is the recommended way to create an OrcErmes instance for
  /// production use.
  ///
  /// [contract] The deployed SignalingContract instance
  /// [accountId] The account ID of the current user
  /// [socket] The transport socket for communication
  /// [enableEncryption] Enable ECDH encryption (default: true)
  /// [connectionTimeoutMs] Connection timeout in milliseconds (default: 30000)
  ///
  /// Returns a new OrcErmes instance ready to use
  static OrcErmes create({
    required SignalingContract contract,
    required IdAccountType accountId,
    required IShspSocket socket,
    bool enableEncryption = true,
    int connectionTimeoutMs = 30000,
  }) =>
      OrcErmes.fromContract(
        contract: contract,
        accountId: accountId,
        socket: socket,
        stunHandlerFactory: StunHandlerFactoryHelper.createDefault,
        enableEncryption: enableEncryption,
        connectionTimeoutMs: connectionTimeoutMs,
      );
}
