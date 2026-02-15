import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import '../../iermes.dart';
/// Input for creating socket callback - uses dynamic to avoid
/// circular dependency
/// In practice, [ermesService] should be of type IErmesService from
/// iermes package
@includeInBarrelFile
class OnSignalCreateSocketCallbackInput {
  /// Creates callback input
  const OnSignalCreateSocketCallbackInput({
    required this.peer,
    required this.ermesService,
  });
  /// The peer identifier
  final IdAccountType peer;
  /// The Ermes service instance
  /// Type: IErmesService from iermes package (using dynamic to avoid
  /// circular import)
  final IErmesService ermesService;
}
/// Callback type for creating a socket when a signal is received
typedef OnSignalCreateSocketCallback =
    void Function(OnSignalCreateSocketCallbackInput input);
