/// Class that represents the requirement for a type to be stored
library;

import '../../iermes.dart';

abstract interface class StorageType {

  factory StorageType.fromJson(Map<String, dynamic> _) =>
      throw UnimplementedError('You need to implement this fromJson method');

  IdType get id;
  Map<String, dynamic> toJson();
  Map<String, dynamic> get json => toJson();
}

