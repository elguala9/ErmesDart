// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations
import 'package:singleton_manager/singleton_manager.dart';
import '../ermes_signaling_handler.dart';
import 'dart:async';
import 'dart:io';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import 'package:stun_shsp/stun_shsp.dart';
import '../../ermes_signaling.dart';

class ErmesSignalingHandlerDI extends ErmesSignalingHandler implements ISingletonStandardDI {

  ErmesSignalingHandlerDI() : super.emptyForDI();

  factory ErmesSignalingHandlerDI.initializeDI() {
    final instance = ErmesSignalingHandlerDI();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
    stunShspHandler = SingletonDIAccess.get<IStunShspHandler>();
    socket = SingletonDIAccess.get<IShspSocket>();
    ermesBookService = SingletonDIAccess.get<IErmesBookService<BookData>>();
  }
}
