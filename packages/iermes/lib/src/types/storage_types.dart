import '../../iermes.dart';

/// Class that rapprest the requirement for a type to be stored
abstract interface class StorageType {

  factory StorageType.fromJson(Map<String, dynamic> json) =>
      throw UnimplementedError("You need to implement this fromJson method");

  IdType get id;
  Map<String, dynamic> toJson();
  Map<String, dynamic> get json => toJson();
}
