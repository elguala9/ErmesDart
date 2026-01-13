import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../ermes_book_repository.dart';

/// 1️⃣1️⃣ Factory per Book
/// Tradotto da: ErmesBookFactories.ts
// ignore: avoid_classes_with_only_static_members
@includeInBarrelFile
class ErmesBookFactories {
  @includeInBarrelFile
  static ErmesBookRepository createRepository() => ErmesBookRepository();
}
