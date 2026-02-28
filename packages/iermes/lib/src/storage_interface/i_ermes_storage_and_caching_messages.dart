

import '../../iermes.dart';

abstract class IErmesStorageAndCachingMessages<DataJson>
    implements IErmesStorageAndCaching<DataJson> {
  // delete all id from 0 to the id passed in input
  void deleteUntil(int id);
}
