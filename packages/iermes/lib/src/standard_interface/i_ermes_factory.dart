import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_types/ermes_types.dart';

import '../signaling_interface/i_ermes_signaling_handler.dart';
import 'i_ermes.dart';

/// Factory interface for creating Ermes instances
///
/// This factory creates both repository and service instances,
/// providing a clean separation between data transport and business logic.
@includeInBarrelFile
abstract class IErmesFactory<SocketType> {
  /// Create a repository instance
  ///
  /// [remotePeerId] The ID of the remote peer to connect to
  /// [ermesSignalingHandler] The signaling handler for peer setup
  /// Returns a new [IErmesRepository] instance
  Future<IErmesRepository> createRepository(
    IdAccountType remotePeerId,
    IErmesSignalingHandler<SocketType> ermesSignalingHandler,
  );

  /// Create a service instance
  ///
  /// [ermesRepository] The repository to wrap with service logic
  /// Returns a new [IErmesService] instance
  IErmesService createService(IErmesRepository ermesRepository);
}
