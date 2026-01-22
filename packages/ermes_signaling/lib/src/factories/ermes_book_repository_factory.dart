import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import '../ermes_book_repository.dart';

@includeInBarrelFile
class ErmesBookRepositoryFactory {
  static IErmesBookRepository<String, BookData> createDefault() =>
      ErmesBookRepository();
}
