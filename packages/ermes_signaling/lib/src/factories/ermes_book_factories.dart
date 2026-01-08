import 'package:barrel_files_annotation/barrel_files_annotation.dart';

import '../ermes_book_repository.dart';

/// 1️⃣1️⃣ Factory per Book
/// Tradotto da: ErmesBookFactories.ts
@includeInBarrelFile
class ErmesBookFactories {
  @includeInBarrelFile
  static ErmesBookRepository createRepository() => ErmesBookRepository();
}
