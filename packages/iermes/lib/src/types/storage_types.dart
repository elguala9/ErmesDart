import '../../iermes.dart';

abstract interface class StorageType {
  IdType get id;
  Map<String, dynamic> get json;
  void fromJson(Map<String, dynamic>);
}
