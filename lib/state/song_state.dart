import 'dart:math' as math;

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
  final List<Note> _clipboard = [];
  int _clipboardInsertCounter = 0;
  double _bpm;
  double _playheadBeat = 0;

  List<Note> notesForTrack(String trackId) {
    final track = _tracks[trackId];
    if (track == null) return const [];
    return track.notes.map((note) => note.copyWith()).toList(growable: false);
  }

  void setNotes(String trackId, List<Note> notes) {
    final track = _tracks[trackId];
    if (track == null) return;
    _tracks[trackId] = track.copyWith(notes: List<Note>.from(notes));
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
    filtered.addAll(insertNotes.map((note) => note.copyWith()));
    filtered.sort((a, b) => a.startBeat.compareTo(b.startBeat));
    _tracks[trackId] = track.copyWith(notes: filtered);
    notifyListeners();
  }

  void addNotes(String trackId, List<Note> notes) {
    final track = _tracks[trackId];
    if (track == null || notes.isEmpty) return;
    final updated = List<Note>.from(track.notes)
      ..addAll(notes.map((note) => note.copyWith()))
      ..sort((a, b) => a.startBeat.compareTo(b.startBeat));
    _tracks[trackId] = track.copyWith(notes: updated);
    notifyListeners();
  }

  List<Note> removeNotes(String trackId, List<Note> notes) {
    final track = _tracks[trackId];
    if (track == null || notes.isEmpty) return const [];
    final removeIds = notes.map((note) => note.id).toSet();
    final removed = track.notes
        .where((note) => removeIds.contains(note.id))
        .map((note) => note.copyWith())
        .toList(growable: false);
    if (removed.isEmpty) {
      return removed;
    }
    final updated =
        track.notes.where((note) => !removeIds.contains(note.id)).toList();
    _tracks[trackId] = track.copyWith(notes: updated);
    notifyListeners();
    return removed;
  }

  List<Note> cutNotes(String trackId, List<Note> notes) {
    final removed = removeNotes(trackId, notes);
    if (removed.isEmpty) return const [];
    copyToClipboard(removed);
    return removed;
  }

  List<Note> pasteClipboard(String trackId, double targetStartBeat) {
    if (_clipboard.isEmpty) return const [];
    final track = _tracks[trackId];
    if (track == null) return const [];
    final minStart =
        _clipboard.map((note) => note.startBeat).reduce(math.min);
    final pasted = _clipboard.map((note) {
      final offset = note.startBeat - minStart;
      return Note(
        id: 'paste_${_clipboardInsertCounter++}_${note.id}',
        pitch: note.pitch,
        startBeat: targetStartBeat + offset,
        duration: note.duration,
        velocity: note.velocity,
      );
    }).toList(growable: false);
    addNotes(trackId, pasted);
    return pasted;
  }

  void copyToClipboard(List<Note> notes) {
    if (notes.isEmpty) return;
    _clipboard
      ..clear()
      ..addAll(notes.map((note) => note.copyWith()));
    notifyListeners();
  }

  void clearClipboard() {
    if (_clipboard.isEmpty) return;
    _clipboard.clear();
    notifyListeners();
  }

  bool get hasClipboard => _clipboard.isNotEmpty;

  double get bpm => _bpm;

  set bpm(double value) {
    if (value == _bpm) return;
    _bpm = value;
    notifyListeners();
  }

  double get playheadBeat => _playheadBeat;

  set playheadBeat(double value) {
    final newValue = value.clamp(0.0, 64.0) as double;
    if ((newValue - _playheadBeat).abs() < 1e-6) return;
    _playheadBeat = newValue;
    notifyListeners();
  }

  Track? trackById(String trackId) {
    final track = _tracks[trackId];
    return track == null ? null : track.copyWith();
  }

  List<Track> get tracks => _tracks.values
      .map((track) => track.copyWith())
      .toList(growable: false);
}
