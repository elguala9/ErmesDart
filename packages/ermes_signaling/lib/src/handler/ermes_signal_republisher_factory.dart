import 'package:iermes/iermes.dart';

import 'ermes_signal_republisher.dart';

/// Factory for [IErmesSignalRepublisher].
class ErmesSignalRepublisherFactory {
  ErmesSignalRepublisherFactory._();

  static IErmesSignalRepublisher create(ErmesSignalRepublisherInput input) =>
      ErmesSignalRepublisher.create(input);
}
