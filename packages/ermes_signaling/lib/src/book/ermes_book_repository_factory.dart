
import 'package:iermes/iermes.dart';

import 'ermes_book_repository.dart';

// ignore: avoid_classes_with_only_static_members
class ErmesBookRepositoryFactory {
  static IErmesBookRepository<BookData> createDefault() =>
      ErmesBookRepository();
}
