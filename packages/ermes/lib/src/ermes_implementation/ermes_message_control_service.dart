import 'package:ermes_types/ermes_types.dart';
import 'package:iermes/iermes.dart';

class ErmesMessageControlServiceOpts {
  ErmesMessageControlServiceOpts({required this.frequencyIdSaveState});
  final int frequencyIdSaveState;
}

class ErmesMessageControlService implements IErmesMessageControlService {
  ErmesMessageControlService(this._repository, this._opts) {
    _repository.setCallbackIdsToRequest(_handleIdsToRequest);
  }
  final IErmesMessageControlRepository _repository;
  final ErmesMessageControlServiceOpts _opts;
  CallbackIdsToRequest? _externalCallback;
  int _idsCountChange = 0;

  @override
  void idArrived(IdType id) {
    _repository.idArrived(id);
  }

  @override
  Future<List<IdType>> idsToRequest() => _repository.idsToRequest();

  @override
  int numberOfMissingIds() => _repository.numberOfMissingIds();

  @override
  void setCallbackIdsToRequest(CallbackIdsToRequest callback) {
    _externalCallback = callback;
  }

  Future<void> _handleIdsToRequest(List<IdType> ids) async {
    await _performInternalOperations(ids);
    if (_externalCallback != null) {
      await _externalCallback!(ids);
    }
  }

  Future<void> _performInternalOperations(List<IdType> ids) async {
    _idsCountChange += 1;
    if (_idsCountChange >= _opts.frequencyIdSaveState) {
      await _repository.saveState();
      _idsCountChange = 0;
    }
  }

  @override
  Future<void> clear() => _repository.clear();

  @override
  Future<void> destroy() => _repository.destroy();

  Future<void> saveState() => _repository.saveState();
}
