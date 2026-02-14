import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:signaling_contract_sdk/generated/signaling_contract.dart';

import '../ermes_signaling_server.dart';

/// Factory for creating ErmesSignalingServer instances
///
/// This factory creates signaling server instances that implement
/// the IErmesSignalingServer interface using the SignalingContract
/// from the blockchain-based signaling SDK.
@includeInBarrelFile
class ErmesSignalingServerFactory {
  /// Private constructor to prevent instantiation
  ErmesSignalingServerFactory._();

  /// Creates a new ErmesSignalingServer instance
  ///
  /// [contract] The deployed SignalingContract instance
  /// [accountId] The account ID of the current user
  /// Returns a new ErmesSignalingServer configured and ready to use
  @includeInBarrelFile
  static ErmesSignalingServer createServer(
    SignalingContract contract,
    IdAccountType accountId,
  ) => ErmesSignalingServer(contract: contract, accountId: accountId);
}
