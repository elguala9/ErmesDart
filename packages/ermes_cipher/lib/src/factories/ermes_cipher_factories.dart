import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import '../ermes_peer_cipher.dart';

/// Creates an ErmesPeerCipher instance for managing peer-to-peer encryption.
///
/// The returned cipher manages separate encrypt and decrypt cipher lists.
/// Use [addEncryptCipher] and [addDecryptCipher] to add ciphers as needed.
@includeInBarrelFile
IErmesPeerCipher createErmesPeerCipher() => ErmesPeerCipher();
