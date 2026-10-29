import 'dart:typed_data';

import 'package:iermes/iermes.dart';

import '../serialization/ermes_send_root_builder.dart';
import '../serialization/ermes_serialization_utils.dart';
import '../support/exceptions.dart';

/// Max bytes of one serialized [MessageRoot] handed to the transport. SHSP
/// prepends a 1-byte data prefix, so the UDP payload is at most this + 1,
/// well below the IPv6 minimum MTU (1280) minus IP/UDP headers and tunnel
/// (VPN/NAT encapsulation) slack.
const int ermesMaxDatagramBytes = 1100;

/// Sizes chunk payloads by measuring real serialized datagrams.
///
/// The wire overhead is not a constant: chunk data is base64-encoded inside
/// the inner JSON (x4/3), and when a cipher is registered the whole inner JSON
/// is encrypted and base64-encoded again (another x4/3 plus IV/padding). A
/// fixed-overhead estimate therefore overflows on encrypted links, so the
/// chunk size is derived from a worst-case probe datagram.
class ErmesDatagramSizer {
  /// Creates a sizer whose chunk size never exceeds [maxChunkData].
  const ErmesDatagramSizer(this.maxChunkData);

  /// Upper bound on raw payload bytes per chunk (configured budget).
  final int maxChunkData;

  /// Largest raw chunk size whose serialized datagram, for [remotePeerId]'s
  /// current cipher state and a message split into roughly [totalLength]
  /// bytes, stays within [ermesMaxDatagramBytes].
  int chunkSizeFor(String remotePeerId, int totalLength) {
    var size = maxChunkData;
    while (size > 1) {
      final roof = (totalLength / size).ceil() + 1;
      final probe = _probeLength(remotePeerId, size, roof);
      if (probe <= ermesMaxDatagramBytes) {
        return size;
      }
      final scaled = size * ermesMaxDatagramBytes ~/ probe;
      size = scaled < size ? scaled : size - 1;
    }
    throw CoreException('No chunk size fits $ermesMaxDatagramBytes bytes');
  }

  /// Serialized length of a worst-case chunk datagram of [size] data bytes.
  int _probeLength(String remotePeerId, int size, int roof) {
    final chunk = ChunkMessage(
      id: 0x7fffffffffffffff,
      data: Uint8List(size),
      refId: '00000000-0000-4000-8000-000000000000',
      index: roof,
      roof: roof,
    );
    final root = buildMessageRoot(MessageType.chunk(chunk), remotePeerId);
    return objectToUint8Array(root).length;
  }
}

/// Throws when [datagram] exceeds [ermesMaxDatagramBytes], so an oversized
/// datagram (which a constrained path would silently drop) is never emitted.
void ensureDatagramFits(Uint8List datagram) {
  if (datagram.length > ermesMaxDatagramBytes) {
    throw CoreException(
      'Datagram of ${datagram.length} B exceeds $ermesMaxDatagramBytes B cap',
    );
  }
}
