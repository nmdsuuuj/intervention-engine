import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/note.dart';

/// ピアノロール画面における選択状態とプレビュー表示を管理するコントローラ。
class PianoRollController extends ChangeNotifier {
  PianoRollController({
    required String trackId,
    required String contextType,
  })  : _trackId = trackId,
        _contextType = contextType;

  String _trackId;
  String get trackId => _trackId;

  set trackId(String value) {
    if (value == _trackId) return;
    _trackId = value;
    _selectedNotes.clear();
    _previewNotes = null;
    notifyListeners();
  }

  String _contextType;
  final List<Note> _selectedNotes = [];
  List<Note>? _previewNotes;

  String get contextType => _contextType;
  set contextType(String value) {
    if (value == _contextType) return;
    _contextType = value;
    notifyListeners();
  }

  UnmodifiableListView<Note> get selectedNotes =>
      UnmodifiableListView(_selectedNotes);

  bool get hasSelection => _selectedNotes.isNotEmpty;

  List<Note>? get previewNotes =>
      _previewNotes == null ? null : List.unmodifiable(_previewNotes!);

  void updateSelection(List<Note> notes) {
    _selectedNotes
      ..clear()
      ..addAll(notes);
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedNotes.isEmpty) return;
    _selectedNotes.clear();
    notifyListeners();
  }

  void setPreviewNotes(List<Note> notes) {
    _previewNotes = List<Note>.from(notes);
    notifyListeners();
  }

  void clearPreviewNotes() {
    if (_previewNotes == null) return;
    _previewNotes = null;
    notifyListeners();
  }
}
