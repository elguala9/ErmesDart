import 'package:barrel_files_annotation/barrel_files_annotation.dart';

/// TODO: Questa è una implementazione temporanea di un singleton manager
/// generico. Valutare se mantenerla o refactor in futuro.

/// Singleton manager generico per gestire un mapping key -> oggetto.
/// Sia la key che l'oggetto sono parametri di tipo generico.
@includeInBarrelFile
class GenericObjectManager<K, V> {

  /// Protected constructor per permettere sottoclassi di estendere
  GenericObjectManager();

  /// Private constructor per il singleton generico
  GenericObjectManager._internal();
  static final Map<String, GenericObjectManager<Object, Object>> _instances =
      {};

  final Map<K, V> _objects = {};

  /// Ottiene l'istanza singleton per la coppia di tipi K, V
  /// Usa una chiave basata sui tipi per distinguere diverse combinazioni
  static GenericObjectManager<K, V> instance<K, V>() {
    final key = '${K}_$V';
    return _instances.putIfAbsent(key, GenericObjectManager._internal)
        as GenericObjectManager<K, V>;
  }

  /// Aggiunge o aggiorna un oggetto con la chiave fornita
  void set(K key, V value) {
    _objects[key] = value;
  }

  /// Recupera un oggetto dalla chiave
  V? get(K key) => _objects[key];

  /// Rimuove un oggetto dalla chiave
  V? remove(K key) => _objects.remove(key);

  /// Verifica se una chiave esiste
  bool contains(K key) => _objects.containsKey(key);

  /// Ottiene tutte le chiavi
  Iterable<K> get keys => _objects.keys;

  /// Ottiene tutti i valori
  Iterable<V> get values => _objects.values;

  /// Pulisce tutti gli oggetti
  void clear() {
    _objects.clear();
  }

  /// Numero di oggetti gestiti
  int get length => _objects.length;
}
