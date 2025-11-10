import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../models/snap_mode.dart';

enum EditorTool { select, draw }

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
  EditorTool _editorTool = EditorTool.select;
  SnapMode _snapMode = SnapMode.beat;
  int _octaveOffset = 0;
  bool _guideVisible = true;
  final List<Note> _selectedNotes = [];
  List<Note>? _previewNotes;

  String get contextType => _contextType;
  set contextType(String value) {
    if (value == _contextType) return;
    _contextType = value;
    notifyListeners();
  }

  int get octaveOffset => _octaveOffset;
  set octaveOffset(int value) {
    if (value == _octaveOffset) return;
    _octaveOffset = value.clamp(-48, 48); // -4オクターブから+4オクターブ
    notifyListeners();
  }

  bool get guideVisible => _guideVisible;
  set guideVisible(bool value) {
    if (value == _guideVisible) return;
    _guideVisible = value;
    notifyListeners();
  }

  UnmodifiableListView<Note> get selectedNotes =>
      UnmodifiableListView(_selectedNotes);

  bool get hasSelection => _selectedNotes.isNotEmpty;

  List<Note>? get previewNotes =>
      _previewNotes == null ? null : List.unmodifiable(_previewNotes!);

  EditorTool get editorTool => _editorTool;
  set editorTool(EditorTool value) {
    if (value == _editorTool) return;
    _editorTool = value;
    notifyListeners();
  }

  bool get isSelectToolActive => _editorTool == EditorTool.select;
  bool get isDrawToolActive => _editorTool == EditorTool.draw;

  SnapMode get snapMode => _snapMode;
  set snapMode(SnapMode value) {
    if (value == _snapMode) return;
    _snapMode = value;
    notifyListeners();
  }

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

  double snapBeat(double rawBeat) {
    switch (_snapMode) {
      case SnapMode.free:
        return rawBeat;
      case SnapMode.bar:
        const beatsPerBar = 4.0;
        return (rawBeat / beatsPerBar).roundToDouble() * beatsPerBar;
      case SnapMode.beat:
        return rawBeat.roundToDouble();
      case SnapMode.grid:
        const gridResolution = 0.25; // 16分音符基準
        return (rawBeat / gridResolution).roundToDouble() * gridResolution;
    }
  }
}
