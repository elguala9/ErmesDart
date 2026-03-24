// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations

import 'package:singleton_manager/singleton_manager.dart';
import '../ermes_message_control_service.dart';
import 'dart:async';
import 'package:callback_handler/callback_handler.dart';
import 'package:iermes/iermes.dart';
import 'package:meta/meta.dart';
import '../../ermes_message_control.dart';

class ErmesMessageControlServiceDI extends ErmesMessageControlService implements ISingletonStandardDI {

  ErmesMessageControlServiceDI() : super();

  factory ErmesMessageControlServiceDI.initializeDI() {
    final instance = ErmesMessageControlServiceDI();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
    repository = SingletonDIAccess.get<IErmesMessageControlRepository>();
  }
}
