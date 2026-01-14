// Test file for ErmesStorageRepository concrete implementation
// Tests the interface contract using testStorageRepository from ermes_test

import 'package:ermes_storage/ermes_storage.dart';
import 'package:ermes_test/ermes_test.dart';
import 'package:ermes_types/ermes_types.dart';
import 'package:work_db/work_db.dart';

void main() async {
  final db = WorkDbFactory.createMemory();

  testStorageRepository<MessageType>(
    'ErmesStorageRepository',
    () => ErmesStorageRepository<MessageType>(db, 'test_messages'),
  );
}
