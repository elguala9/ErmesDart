import 'package:iermes/iermes.dart';

import 'ermes_signal_last_seen_store.dart';

/// Input for [ErmesSignalLastSeenStoreFactory.create]. The store owns no
/// collaborators; the input exists to keep the factory contract uniform.
class ErmesSignalLastSeenStoreInput {
  /// Creates the input.
  const ErmesSignalLastSeenStoreInput();
}

/// Factory for [IErmesSignalLastSeenStore] instances.
class ErmesSignalLastSeenStoreFactory {
  ErmesSignalLastSeenStoreFactory._();

  /// Creates a fresh, empty store.
  static IErmesSignalLastSeenStore create(
    ErmesSignalLastSeenStoreInput input,
  ) =>
      ErmesSignalLastSeenStore();
}
