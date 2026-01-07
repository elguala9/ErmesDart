import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import 'i_ermes_signaling.dart';
import 'i_ermes_signaling_handler.dart';
import 'i_ermes_signaling_server.dart';

/// Factory interface for creating signaling instances
///
/// This factory creates signaling repositories that combine
/// signaling servers with signaling handlers.
// ignore: one_member_abstracts
@includeInBarrelFile
abstract class IErmesSignalingFactory {
  /// Create a signaling repository
  ///
  /// [signalingServer] The server that handles signal transmission
  /// [signalHandler] The handler that manages peer connections
  /// Returns a new signaling repository instance
  IErmesSignalingRepository<ISignalType> create(
    IErmesSignalingServer signalingServer,
    IErmesSignalingHandler<Object> signalHandler,
  );
}
