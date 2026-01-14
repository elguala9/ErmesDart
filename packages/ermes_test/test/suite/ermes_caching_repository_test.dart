// Test file for ErmesCachingRepository concrete implementation
// Tests the interface contract using testCachingRepository from ermes_test

import 'package:ermes_storage/ermes_storage.dart';
import 'package:ermes_test/ermes_test.dart';
import 'package:ermes_types/ermes_types.dart';

void main() {
  // Note: This test validates interface contracts without concrete data
  // since MessageType is a sealed class
  testCachingRepository<MessageType>(
    'ErmesCachingRepository',
    () => ErmesCachingRepository<MessageType>(100),
  );
}
