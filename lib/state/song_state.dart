import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../models/track.dart';

/// 曲全体のノート状態を保持し、Undo/Redoに対応できるようにする。
class SongState extends ChangeNotifier {
  SongState({
    List<Track>? initialTracks,
    double bpm = 120,
  })  : _tracks = {
          for (final track in initialTracks ?? const <Track>[])
            track.id: track.copyWith(),
        },
        _bpm = bpm;

  final Map<String, Track> _tracks;
  double _bpm;

  List<Note> notesForTrack(String trackId) {
    final track = _tracks[trackId];
    if (track == null) return const [];
    return List<Note>.from(track.notes);
  }

  void setNotes(String trackId, List<Note> notes) {
    final track = _tracks[trackId];
    if (track == null) return;
    _tracks[trackId] = track.copyWith(notes: notes);
    notifyListeners();
  }

  /// 対象トラックのノートを置換する。
  void replaceNotes(
    String trackId, {
    required List<Note> removeTargets,
    required List<Note> insertNotes,
  }) {
    final track = _tracks[trackId];
    if (track == null) return;
    final current = List<Note>.from(track.notes);
    final removeIds = removeTargets.map((note) => note.id).toSet();
    final filtered = current.where((note) => !removeIds.contains(note.id)).toList();
    filtered.addAll(insertNotes);
    filtered.sort((a, b) => a.startBeat.compareTo(b.startBeat));
    _tracks[trackId] = track.copyWith(notes: filtered);
    notifyListeners();
  }

  double get bpm => _bpm;

  set bpm(double value) {
    if (value == _bpm) return;
    _bpm = value;
    notifyListeners();
  }

  Track? trackById(String trackId) {
    final track = _tracks[trackId];
    return track == null ? null : track.copyWith();
  }

  List<Track> get tracks =>
      _tracks.values.map((track) => track.copyWith()).toList(growable: false);
}
