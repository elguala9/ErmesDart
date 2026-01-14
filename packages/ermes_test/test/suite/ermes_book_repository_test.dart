import 'package:ermes_signaling/ermes_signaling.dart';
import 'package:ermes_test/ermes_test.dart';

void main() {
  testIErmesBookRepository<String, BookData>(
    'ErmesBookRepository',
    ErmesBookRepository.new,
  );
}
