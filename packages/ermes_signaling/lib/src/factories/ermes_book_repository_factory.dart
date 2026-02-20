import 'package:barrel_files_annotation/barrel_files_annotation.dart';
import 'package:iermes/iermes.dart';

import '../ermes_book_repository.dart';

// ignore: avoid_classes_with_only_static_members
@includeInBarrelFile
class ErmesBookRepositoryFactory {
  static IErmesBookRepository createDefault() =>
      ErmesBookRepository();
}
