import 'package:barrel_files_annotation/barrel_files_annotation.dart';

/// Type alias per il tipo generico di storage
@includeInBarrelFile
typedef StorageType<DataJson> = DataJson;

/// Type alias per i messaggi nel storage
@includeInBarrelFile
typedef MessageTypeStorage = dynamic;

/// Type alias per il servizio di messaggi nel storage
@includeInBarrelFile
typedef ServiceMessageStorage = dynamic;

/// Type alias per i dati dei messaggi nel storage
@includeInBarrelFile
typedef MessageDataStorage = dynamic;

/// Type alias per i chunk di messaggi nel storage
@includeInBarrelFile
typedef MessageChunkStorage = dynamic;
