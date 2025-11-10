import 'package:flutter/foundation.dart';

typedef UndoCallback = void Function();

class UndoEntry {
  UndoEntry({
    required this.description,
    required this.undo,
    required this.redo,
  });

  final String description;
  final UndoCallback undo;
  final UndoCallback redo;
}

/// `[ Undo ]` / `[ Redo ]` ボタンと連動するスタック実装。
class UndoManager extends ChangeNotifier {
  final List<UndoEntry> _entries = [];
  int _cursor = -1;

  bool get canUndo => _cursor >= 0;
  bool get canRedo => _cursor < _entries.length - 1;

  void push(UndoEntry entry) {
    if (_cursor < _entries.length - 1) {
      _entries.removeRange(_cursor + 1, _entries.length);
    }
    _entries.add(entry);
    _cursor = _entries.length - 1;
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    final entry = _entries[_cursor];
    entry.undo();
    _cursor -= 1;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _cursor += 1;
    final entry = _entries[_cursor];
    entry.redo();
    notifyListeners();
  }
}
