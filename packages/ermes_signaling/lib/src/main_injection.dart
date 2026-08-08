// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:iermes/iermes.dart';
import 'package:singleton_manager/singleton_manager.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND

import 'book/ermes_book_repository.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'book/ermes_book_service.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'handler/ermes_signaling_handler.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'handler/ermes_signaling_repository.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'handler/ermes_signaling_service.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND
import 'server/ermes_signaling_server.dart'; // GENERATED CODE - DO NOT MODIFY BY HAND

/// Connects every `@dependencyInjectable` class discovered under the scanned
/// input directory to `RegistryManager.instance`, using each generated
/// `dependencyInjectionFactory()` as the connected factory.
/// Each call is independent — registering under a different [key] never
/// overwrites a previous call, so multiple singleton graphs can be set up
/// side by side by calling this with different keys.
///
/// Every method below is a regular, overridable instance method — mix
/// [MainInjectionErmesSignalingMixin] into your own class (or override on [MainInjectionErmesSignaling])
/// to hook into `beforeRegisterAllSingletonsErmesSignaling` / `afterRegisterAllSingletonsErmesSignaling`, or replace
/// `registerAllSingletonsErmesSignaling` entirely.
mixin MainInjectionErmesSignalingMixin {
  // GENERATED CODE - DO NOT MODIFY BY HAND
  /// Called by [registerAllSingletonsErmesSignaling] right before it connects anything.
  /// Override to customize. // GENERATED CODE - DO NOT MODIFY BY HAND
  void beforeRegisterAllSingletonsErmesSignaling({
    String key = 'default',
  }) {} // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Connects every discovered singleton under [key]. // GENERATED CODE - DO NOT MODIFY BY HAND
  void registerAllSingletonsErmesSignaling({String key = 'default'}) {
    // GENERATED CODE - DO NOT MODIFY BY HAND
    beforeRegisterAllSingletonsErmesSignaling(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    RegistryManager
        .instance // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IErmesBookRepository, ErmesBookRepository>(
        () => ErmesBookRepository.dependencyInjectionFactory(key: key),
        key: key,
      ) // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IErmesBookService, ErmesBookServiceBase>(
        () => ErmesBookServiceBase.dependencyInjectionFactory(key: key),
        key: key,
      ) // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IErmesSignalingHandler, ErmesSignalingHandler>(
        () => ErmesSignalingHandler.dependencyInjectionFactory(key: key),
        key: key,
      ) // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IErmesSignalingRepository, ErmesSignalingRepository>(
        () => ErmesSignalingRepository.dependencyInjectionFactory(key: key),
        key: key,
      ) // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IErmesSignalingService, ErmesSignalingService>(
        () => ErmesSignalingService.dependencyInjectionFactory(key: key),
        key: key,
      ) // GENERATED CODE - DO NOT MODIFY BY HAND
      ..connectInstance<IErmesSignalingServer, ErmesSignalingServer>(
        () => ErmesSignalingServer.dependencyInjectionFactory(key: key),
        key: key,
      ); // GENERATED CODE - DO NOT MODIFY BY HAND
    afterRegisterAllSingletonsErmesSignaling(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Called by [registerAllSingletonsErmesSignaling] right after it finishes connecting
  /// everything. Override to customize. // GENERATED CODE - DO NOT MODIFY BY HAND
  void afterRegisterAllSingletonsErmesSignaling({
    String key = 'default',
  }) {} // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Called by [registerAllSingletonsErmesSignalingAsync] right before it connects anything.
  /// Override to customize. // GENERATED CODE - DO NOT MODIFY BY HAND
  Future<void> beforeRegisterAllSingletonsErmesSignalingAsync({
    String key = 'default',
  }) async {} // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Async twin of [registerAllSingletonsErmesSignaling] — use this when [beforeRegisterAllSingletonsErmesSignalingAsync]
  /// or [afterRegisterAllSingletonsErmesSignalingAsync] need to await work (e.g. loading remote
  /// config) before or after connecting. // GENERATED CODE - DO NOT MODIFY BY HAND
  Future<void> registerAllSingletonsErmesSignalingAsync({
    String key = 'default',
  }) async {
    // GENERATED CODE - DO NOT MODIFY BY HAND
    await beforeRegisterAllSingletonsErmesSignalingAsync(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    registerAllSingletonsErmesSignaling(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
    await afterRegisterAllSingletonsErmesSignalingAsync(
      key: key,
    ); // GENERATED CODE - DO NOT MODIFY BY HAND
  } // GENERATED CODE - DO NOT MODIFY BY HAND

  /// Called by [registerAllSingletonsErmesSignalingAsync] right after it finishes connecting
  /// everything. Override to customize. // GENERATED CODE - DO NOT MODIFY BY HAND
  Future<void> afterRegisterAllSingletonsErmesSignalingAsync({
    String key = 'default',
  }) async {} // GENERATED CODE - DO NOT MODIFY BY HAND
} // GENERATED CODE - DO NOT MODIFY BY HAND

/// Ready-to-use [MainInjectionErmesSignalingMixin] host — instantiate this directly, or
/// extend it (or mix [MainInjectionErmesSignalingMixin] into your own class) to override
/// the before/register/after hooks. // GENERATED CODE - DO NOT MODIFY BY HAND
class MainInjectionErmesSignaling with MainInjectionErmesSignalingMixin {
  // GENERATED CODE - DO NOT MODIFY BY HAND
  const MainInjectionErmesSignaling(); // GENERATED CODE - DO NOT MODIFY BY HAND
} // GENERATED CODE - DO NOT MODIFY BY HAND
