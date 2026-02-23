import '../../iermes.dart';

abstract interface class StorageType {
  /// Factory that delegates to MessageType (current only implementation)
  /// In the future, when more StorageType subclasses exist,
  /// this can be updated to use a type discriminator from the JSON
  factory StorageType.fromJson(Map<String, dynamic> json) =>
      MessageType.fromJson(json);

  IdType get id;
  Map<String, dynamic> toJson();
  Map<String, dynamic> get json => toJson();
}
