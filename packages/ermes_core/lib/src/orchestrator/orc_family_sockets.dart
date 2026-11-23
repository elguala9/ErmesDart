import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

import '../support/exceptions.dart';

/// The SHSP sockets an orchestrator can dial over, one per address family.
///
/// Each family is optional (a host may lack IPv4 or IPv6), but at least one
/// must be present.
class OrcFamilySockets {
  /// Builds the set from the per-family sockets; throws [CoreException] when
  /// both are absent.
  factory OrcFamilySockets({IShspSocket? ipv4, IShspSocket? ipv6}) {
    final sockets = <ErmesConnectionContext, IShspSocket>{
      if (ipv4 != null) ErmesConnectionContext.ipv4: ipv4,
      if (ipv6 != null) ErmesConnectionContext.ipv6: ipv6,
    };
    if (sockets.isEmpty) {
      throw CoreException('At least one IPv4 or IPv6 socket is required');
    }
    return OrcFamilySockets._(sockets);
  }

  const OrcFamilySockets._(this._sockets);

  final Map<ErmesConnectionContext, IShspSocket> _sockets;

  /// Families this host can dial over.
  List<ErmesConnectionContext> get contexts => _sockets.keys.toList();

  /// Whether a socket exists for [context].
  bool has(ErmesConnectionContext context) => _sockets.containsKey(context);

  /// Socket of [context]; throws when that family is not available.
  IShspSocket of(ErmesConnectionContext context) =>
      _sockets[context] ??
      (throw CoreException('No ${context.label} socket available'));
}
