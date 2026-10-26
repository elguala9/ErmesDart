// stdout is the test transport in CI; printing is intentional.
// ignore_for_file: avoid_print

import 'package:stun_shsp/stun_shsp.dart'
    show IShspSocket, IShspSocketMigratable, RegistryManager;

/// Sockets already wired with the error/close loggers, so a socket swapped in
/// by a migration gets its own loggers exactly once.
final Set<IShspSocket> _watched = Set<IShspSocket>.identity();

/// Attaches `[SOCKET-DIAG]` error/close loggers to the IPv4 SHSP socket and
/// its migratable wrapper registered under [key].
///
/// Dart closes a datagram socket on any error event (e.g. an ICMP
/// unreachable) and SHSP only forwards that error to its callbacks, so
/// without these loggers a dead socket only shows up later as a send that
/// returns 0.
void watchShspSocket(String tag, {String key = 'default'}) {
  for (final (name, socket) in _resolve(key)) {
    if (socket == null || !_watched.add(socket)) {
      continue;
    }
    socket.onError.register((err) {
      print('[$tag] [SOCKET-DIAG] $name error -> socket closes: $err');
    });
    socket.onClose.register((_) {
      print('[$tag] [SOCKET-DIAG] $name closed');
    });
  }
}

/// Prints the state of the IPv4 SHSP socket and its wrapper right before a
/// dial: whether each is closed and which local port each is bound to, so a
/// closed or mismatched socket is visible on the attempt that fails.
void logShspSocketHealth(String tag, int attempt, {String key = 'default'}) {
  final parts = <String>[];
  for (final (name, socket) in _resolve(key)) {
    parts.add(
      socket == null
          ? '$name=unregistered'
          : '$name(closed=${socket.isClosed} '
                'port=${_portOf(socket)})',
    );
  }
  print('[$tag] [SOCKET-DIAG] attempt $attempt: ${parts.join(' ')}');
  watchShspSocket(tag, key: key);
}

List<(String, IShspSocket?)> _resolve(String key) {
  final registry = RegistryManager.instance;
  return [
    (
      'socket',
      registry.tryGetInstance<IShspSocket>(key: key, subkey: 'ipv4'),
    ),
    (
      'migratable',
      registry.tryGetInstance<IShspSocketMigratable>(key: key, subkey: 'ipv4'),
    ),
  ];
}

String _portOf(IShspSocket socket) {
  try {
    return socket.socket.port.toString();
  } on Object catch (e) {
    return 'n/a ($e)';
  }
}
