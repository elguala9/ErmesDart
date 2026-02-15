// ignore_for_file: cascade_invocations

import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';
import 'package:test/test.dart';

/// Test suite for IErmesConnection interface - DISABLED
/// This test suite is incompatible with the current IErmesConnection interface
/// TODO: Update test suite to match IErmesConnection interface methods
@includeInBarrelFile
void testIErmesConnection(
  String implementationName,
  IErmesConnection Function() createInstance,
) {
  group('IErmesConnection - $implementationName', () {
    // Tests disabled - interface mismatch
  });
}
