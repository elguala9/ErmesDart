import '../../exceptions/ermes_exception.dart';

/// Ermes protocol version carried in the outer envelope field `v`
/// (RFC ermes-protocol, section 7.1).
///
/// On the wire the version is the string "X.Y" where X (major) and Y (minor)
/// are non-negative decimal integers. Receivers branch on the major only.
class ProtocolVersion {
  /// Creates a version from its [major] and [minor] components.
  const ProtocolVersion(this.major, this.minor);

  /// Parses the raw `v` value of an envelope.
  ///
  /// An absent value ([raw] null) is the legacy unversioned form "1.0".
  /// Anything other than a well-formed "X.Y" string throws
  /// [ErmesSerializationException].
  factory ProtocolVersion.parse(Object? raw) {
    if (raw == null) {
      return legacy;
    }
    if (raw is! String) {
      throw ErmesSerializationException(
        'Envelope version must be a "X.Y" string, got ${raw.runtimeType}',
      );
    }
    final match = _pattern.firstMatch(raw);
    if (match == null) {
      throw ErmesSerializationException('Malformed envelope version "$raw"');
    }
    return ProtocolVersion(
      int.parse(match.group(1) ?? ''),
      int.parse(match.group(2) ?? ''),
    );
  }

  static final RegExp _pattern = RegExp(r'^(\d+)\.(\d+)$');

  /// The version this implementation emits.
  static const ProtocolVersion current = ProtocolVersion(3, 0);

  /// The legacy unversioned envelope (absent `v`).
  static const ProtocolVersion legacy = ProtocolVersion(1, 0);

  /// Majors this implementation can parse.
  static const Set<int> supportedMajors = {1, 3};

  /// Major component; a change means an incompatible wire format.
  final int major;

  /// Minor component; a change is backward compatible.
  final int minor;

  /// Whether this implementation can parse envelopes of this version.
  bool get isSupported => supportedMajors.contains(major);

  /// Throws [ErmesSerializationException] unless [isSupported].
  void requireSupported() {
    if (!isSupported) {
      throw ErmesSerializationException(
        'Unsupported envelope protocol major version $major',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ProtocolVersion && other.major == major && other.minor == minor;

  @override
  int get hashCode => Object.hash(major, minor);

  /// Wire form "X.Y".
  @override
  String toString() => '$major.$minor';
}
