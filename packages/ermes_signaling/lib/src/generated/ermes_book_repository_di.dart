// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations
import 'package:singleton_manager/singleton_manager.dart';
import '../ermes_book_repository.dart';
import 'package:iermes/iermes.dart';
import 'package:stun_shsp/stun_shsp.dart';

class ErmesBookRepositoryDI extends ErmesBookRepository implements ISingletonStandardDI {

  ErmesBookRepositoryDI() : super.emptyForDI();

  factory ErmesBookRepositoryDI.initializeDI() {
    final instance = ErmesBookRepositoryDI();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
  }
}
