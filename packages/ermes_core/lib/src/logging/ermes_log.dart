import 'package:logging/logging.dart';

/// Shared logger for the `ermes_core` package, based on `package:logging`.
///
/// Following the `package:logging` convention, a library only *emits* log
/// records; it never decides where they go. By default no output is produced.
/// A host application opts in by listening to the logging hierarchy, e.g.:
///
/// ```dart
/// import 'package:logging/logging.dart';
///
/// Logger.root.level = Level.INFO;
/// Logger.root.onRecord.listen((record) {
///   print('${record.level.name}: ${record.loggerName}: ${record.message}');
/// });
/// ```
///
/// Use named child loggers (`ermesCoreLogger.named('ErmesService')`) so callers
/// can filter by subsystem.
final Logger ermesCoreLogger = Logger('ermes_core');

/// Returns a child logger named `ermes_core.<name>` for a specific subsystem.
Logger ermesLoggerFor(String name) => Logger('ermes_core.$name');
