import 'dart:collection';

/// Observable FIFO queue with efficient O(1) operations.
///
/// This queue provides efficient add/remove operations (O(1)) compared to
/// list-based implementations (O(n)). It also supports callbacks when
/// items are added, making it suitable for reactive data structures.
///
/// Example:
/// ```dart
/// final queue = ObservableQueue<int>();
/// queue.onAdd(() => print('Item added'));
/// queue.push(42); // Prints: Item added
/// final value = queue.shift(); // Returns 42
/// ```
class ObservableQueue<T> {
  /// Creates an observable queue with optional max size limit.
  ///
  /// If [maxSize] is specified, attempting to add items beyond the limit
  /// will throw a [StateError].
  ObservableQueue([this._maxSize]);

  final Queue<T> _items = Queue<T>();
  final int? _maxSize;
  void Function()? onAddCallback;

  /// Adds an item to the end of the queue - O(1) operation.
  ///
  /// Throws [StateError] if the queue is at max capacity.
  void push(T item) {
    if (_maxSize != null && _items.length >= _maxSize) {
      throw StateError('Buffer is full (max: $_maxSize)');
    }
    _items.add(item);
    onAddCallback?.call();
  }

  /// Removes and returns the first item from the queue - O(1) operation.
  ///
  /// Throws [StateError] if the queue is empty.
  T shift() {
    if (_items.isEmpty) {
      throw StateError('Buffer is empty');
    }
    return _items.removeFirst();
  }

  /// Returns true if the queue is empty, false otherwise.
  bool isEmpty() => _items.isEmpty;

  /// Returns the current number of items in the queue.
  int get length => _items.length;

  /// Removes all items from the queue.
  void clear() {
    _items.clear();
  }
}
