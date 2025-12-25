// ignore_for_file: prefer_const_constructors

import 'package:ermes_types/ermes_types.dart';
import 'package:test/test.dart';

void main() {
  group('PaginationDto', () {
    test('should create instance with all required fields', () {
      final pagination = PaginationDto<String, int>(
        cursor: 0,
        pageSize: 10,
        totalItems: 100,
        eof: false,
        items: ['item1', 'item2', 'item3'],
        nextCursor: 10,
      );

      expect(pagination.cursor, equals(0));
      expect(pagination.pageSize, equals(10));
      expect(pagination.totalItems, equals(100));
      expect(pagination.eof, isFalse);
      expect(pagination.items, equals(['item1', 'item2', 'item3']));
      expect(pagination.nextCursor, equals(10));
    });

    test('should support different cursor types', () {
      // Integer cursor
      final intCursor = PaginationDto<String, int>(
        cursor: 0,
        pageSize: 10,
        totalItems: 50,
        eof: false,
        items: [],
        nextCursor: 10,
      );
      expect(intCursor.cursor, isA<int>());

      // String cursor
      final stringCursor = PaginationDto<String, String>(
        cursor: 'abc',
        pageSize: 10,
        totalItems: 50,
        eof: false,
        items: [],
        nextCursor: 'def',
      );
      expect(stringCursor.cursor, isA<String>());
    });

    test('should indicate end of data with eof flag', () {
      final lastPage = PaginationDto<String, int>(
        cursor: 90,
        pageSize: 10,
        totalItems: 100,
        eof: true,
        items: ['item91', 'item92'],
        nextCursor: 100,
      );

      expect(lastPage.eof, isTrue);
      expect(lastPage.hasMore, isFalse);
      expect(lastPage.isLastPage, isTrue);
    });

    test('hasMore should return correct value', () {
      final withMore = PaginationDto<int, int>(
        cursor: 0,
        pageSize: 10,
        totalItems: 100,
        eof: false,
        items: [1, 2, 3],
        nextCursor: 10,
      );

      final withoutMore = PaginationDto<int, int>(
        cursor: 90,
        pageSize: 10,
        totalItems: 100,
        eof: true,
        items: [91, 92],
        nextCursor: 100,
      );

      expect(withMore.hasMore, isTrue);
      expect(withoutMore.hasMore, isFalse);
    });

    test('isEmpty should return correct value', () {
      final empty = PaginationDto<String, int>(
        cursor: 0,
        pageSize: 10,
        totalItems: 0,
        eof: true,
        items: [],
        nextCursor: 0,
      );

      final notEmpty = PaginationDto<String, int>(
        cursor: 0,
        pageSize: 10,
        totalItems: 3,
        eof: true,
        items: ['a', 'b', 'c'],
        nextCursor: 3,
      );

      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);
      expect(notEmpty.isEmpty, isFalse);
      expect(notEmpty.isNotEmpty, isTrue);
    });

    test('itemCount should return correct count', () {
      final pagination = PaginationDto<String, int>(
        cursor: 0,
        pageSize: 10,
        totalItems: 100,
        eof: false,
        items: ['a', 'b', 'c', 'd', 'e'],
        nextCursor: 5,
      );

      expect(pagination.itemCount, equals(5));
      expect(pagination.items.length, equals(5));
    });

    test('should work with complex item types', () {
      final pagination = PaginationDto<Map<String, dynamic>, String>(
        cursor: 'start',
        pageSize: 2,
        totalItems: 4,
        eof: false,
        items: [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ],
        nextCursor: 'next',
      );

      expect(pagination.items.length, equals(2));
      expect(pagination.items[0]['id'], equals(1));
      expect(pagination.items[1]['name'], equals('Item 2'));
    });

    test('should handle edge cases', () {
      // Empty first page
      final emptyFirst = PaginationDto<String, int>(
        cursor: 0,
        pageSize: 10,
        totalItems: 0,
        eof: true,
        items: [],
        nextCursor: 0,
      );

      expect(emptyFirst.isEmpty, isTrue);
      expect(emptyFirst.isLastPage, isTrue);

      // Single item total
      final singleItem = PaginationDto<String, int>(
        cursor: 0,
        pageSize: 10,
        totalItems: 1,
        eof: true,
        items: ['only'],
        nextCursor: 1,
      );

      expect(singleItem.itemCount, equals(1));
      expect(singleItem.isLastPage, isTrue);
    });

    test('should support copyWith', () {
      final original = PaginationDto<String, int>(
        cursor: 0,
        pageSize: 10,
        totalItems: 100,
        eof: false,
        items: ['a', 'b'],
        nextCursor: 10,
      );

      final modified = original.copyWith(
        cursor: 10,
        items: ['c', 'd'],
        nextCursor: 20,
      );

      expect(modified.cursor, equals(10));
      expect(modified.items, equals(['c', 'd']));
      expect(modified.nextCursor, equals(20));
      expect(modified.pageSize, equals(original.pageSize));
      expect(modified.totalItems, equals(original.totalItems));
    });
  });
}
