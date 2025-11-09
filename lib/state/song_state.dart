import 'package:flutter/foundation.dart';

import '../models/note.dart';

/// 曲全体のノート状態を保持し、Undo/Redoに対応できるようにする。
class SongState extends ChangeNotifier {
  SongState({
    Map<String, List<Note>>? initialTracks,
  }) : _trackNotes = initialTracks != null
            ? initialTracks.map(
                (key, value) => MapEntry(key, List<Note>.from(value)),
              )
            : {};

  final Map<String, List<Note>> _trackNotes;

  List<Note> notesForTrack(String trackId) {
    return List<Note>.from(_trackNotes[trackId] ?? const []);
  }

  void setNotes(String trackId, List<Note> notes) {
    _trackNotes[trackId] = List<Note>.from(notes);
    notifyListeners();
  }

  /// 対象トラックのノートを置換する。
  void replaceNotes(
    String trackId, {
    required List<Note> removeTargets,
    required List<Note> insertNotes,
  }) {
    final current = List<Note>.from(_trackNotes[trackId] ?? const []);
    final removeIds = removeTargets.map((note) => note.id).toSet();
    final filtered = current.where((note) => !removeIds.contains(note.id)).toList();
    filtered.addAll(insertNotes);
    filtered.sort((a, b) => a.startBeat.compareTo(b.startBeat));
    _trackNotes[trackId] = filtered;
    notifyListeners();
  }
}
