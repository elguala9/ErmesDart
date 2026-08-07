import 'package:ermes_id_handler/ermes_id_handler.dart';
import 'package:iermes/iermes.dart';

/// Factory helper for creating IIdHandlerService instances
///
/// IIdHandlerService is responsible for generating and tracking unique
/// message IDs across P2P connections. Each ErmesPeer needs its own
/// ID handler to maintain independent ID sequences.
class ErmesIdHandlerFactoryHelper {
  /// Private constructor to prevent instantiation
  ErmesIdHandlerFactoryHelper._();

  /// Creates a default IIdHandlerService instance
  ///
  /// Uses default configuration with standard ID range (0 to 2^53-1).
  /// Suitable for most use cases.
  ///
  /// Returns a new IIdHandlerService instance with default configuration
  static IIdHandlerService createDefault() =>
      IdHandlerServiceFactory.createDefault();

  /// Creates an IIdHandlerService with custom ID range
  ///
  /// [start] The starting ID value (default: 0)
  /// [max] The maximum ID value (default: 2^53-1)
  ///
  /// Returns a new IIdHandlerService instance with custom range
  static IIdHandlerService createWithRange({
    int start = 0,
    int max = 9007199254740991, // 2^53 - 1
  }) =>
      IdHandlerServiceFactory.createWithRange(
        start: start,
        max: max,
      );

  /// Creates an IIdHandlerService with custom storage
  ///
  /// [storage] Custom storage handler for persisting IDs across sessions
  ///
  /// Returns a new IIdHandlerService instance with custom storage
  static IIdHandlerService createWithStorage(
    IIdHandlerStorageService storage,
  ) =>
      IdHandlerServiceFactory.createWithStorage(storage);

  /// Creates an IIdHandlerService for testing
  ///
  /// Uses a small ID range (0 to 1000) for quick testing.
  /// IDs are not persisted.
  ///
  /// Returns a new IIdHandlerService instance configured for testing
  static IIdHandlerService createForTesting() =>
      IdHandlerServiceFactory.createWithRange(
        start: 0,
        max: 1000,
      );

  /// Creates multiple IIdHandlerService instances for multiple peers
  ///
  /// [count] Number of handlers to create
  /// [startBase] Base starting ID for first handler
  ///
  /// Returns a list of IIdHandlerService instances, each with unique ID range
  static List<IIdHandlerService> createMultiple({
    required int count,
    int startBase = 0,
  }) {
    const rangeSize = 1000000;
    return List.generate(
      count,
      (i) => IdHandlerServiceFactory.createWithRange(
        start: startBase + (i * rangeSize),
        max: startBase + ((i + 1) * rangeSize) - 1,
      ),
    );
  }
}
