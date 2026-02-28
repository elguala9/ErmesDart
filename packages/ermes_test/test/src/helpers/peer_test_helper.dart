import 'dart:typed_data';

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';

/// Helper per creare e configurare peer per test
///
/// Fornisce factory per creare istanze standard per test multi-peer

class PeerTestHelper {
  PeerTestHelper._();

  /// Crea un IdHandler usando la factory
  static IIdHandlerService createIdHandler() =>
      IdHandlerServiceFactory.createDefault();

  /// Crea dati di test di una certa dimensione
  ///
  /// [size] La dimensione in byte
  /// [pattern] Il pattern da ripetere (default: [0xFF])
  static Uint8List createTestData(
    int size, {
    int pattern = 0xFF,
  }) {
    final data = Uint8List(size);
    for (var i = 0; i < size; i++) {
      data[i] = pattern;
    }
    return data;
  }

  /// Crea multipli messaggi di test
  ///
  /// [count] Il numero di messaggi
  /// [size] La dimensione di ogni messaggio in byte
  static List<Uint8List> createTestMessages(
    int count, {
    int size = 100,
  }) =>
      List.generate(
        count,
        (i) => createTestData(size, pattern: i % 256),
      );

  /// Verifica se due Uint8List sono uguali
  static bool areDataEqual(Uint8List data1, Uint8List data2) {
    if (data1.length != data2.length) {
      return false;
    }
    for (var i = 0; i < data1.length; i++) {
      if (data1[i] != data2[i]) {
        return false;
      }
    }
    return true;
  }
}
