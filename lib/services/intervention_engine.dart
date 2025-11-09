import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/note.dart';
import '../models/technique.dart';

/// 「介入エンジン」の中核ロジック。
class InterventionEngine {
  InterventionEngine({
    AssetBundle? bundle,
    String? assetPath,
  })  : _bundle = bundle ?? rootBundle,
        _assetPath = assetPath ?? 'assets/data/techniques.json';

  final AssetBundle _bundle;
  final String _assetPath;

  List<Technique>? _cachedTechniques;
  final Map<String, Random> _randomPool = {};
  int _tensionNoteCounter = 0;

  Future<void> loadTechniques() async {
    if (_cachedTechniques != null) return;
    final raw = await _bundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    _cachedTechniques = decoded
        .map((entry) => Technique.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<Technique>> getApplicableTechniques(
    List<Note> _selectedNotes, {
    required String contextType,
  }) async {
    await loadTechniques();
    final cache = _cachedTechniques ?? const [];
    if (contextType.isEmpty) {
      return cache;
    }
    return cache
        .where(
          (technique) =>
              technique.type == contextType || technique.type == 'any',
        )
        .toList(growable: false);
  }

  Future<List<Note>> applyTechnique(
    List<Note> originalNotes,
    String techniqueId, {
    required double bpm,
  }) async {
    await loadTechniques();
    switch (techniqueId) {
      case 'TECH_001':
        return _applyPaulStyleOctaveLeaps(originalNotes);
      case 'TECH_002':
        return _applyJDillaGroove(
          originalNotes,
          bpm: bpm,
        );
      case 'TECH_003':
        return _applyAddTensionNotes(originalNotes);
      default:
        // ひとまずその他の技法は変化なし（スタブ実装）
        return originalNotes
            .map((note) => note.copyWith())
            .toList(growable: false);
    }
  }

  List<Note> _applyPaulStyleOctaveLeaps(List<Note> originalNotes) {
    final random = _randomPool.putIfAbsent('TECH_001', Random.new);
    return originalNotes
        .map((note) {
          final direction = random.nextBool() ? 1 : -1;
          final shifted =
              (note.pitch + direction * 12).clamp(0, 127).toInt();
          return note.copyWith(pitch: shifted);
        })
        .toList(growable: false);
  }

  List<Note> _applyJDillaGroove(
    List<Note> originalNotes, {
    required double bpm,
  }) {
    final currentBpm = max(bpm, 1.0);
    final beatDurationMs = 60000 / currentBpm;
    final random = _randomPool.putIfAbsent('TECH_002', Random.new);

    return originalNotes
        .map((note) {
          final delayMs = random.nextInt(16) + 5; // 5〜20ms
          final originalMs = note.startBeat * beatDurationMs;
          final shiftedBeat =
              (originalMs + delayMs) / beatDurationMs;
          return note.copyWith(startBeat: shiftedBeat);
        })
        .toList(growable: false);
  }

  List<Note> _applyAddTensionNotes(List<Note> originalNotes) {
    if (originalNotes.isEmpty) {
      return originalNotes
          .map((note) => note.copyWith())
          .toList(growable: false);
    }
    final random = _randomPool.putIfAbsent('TECH_003', Random.new);
    final mutated =
        originalNotes.map((note) => note.copyWith()).toList(growable: true);
    final highest = mutated.reduce(
      (current, note) => note.pitch > current.pitch ? note : current,
    );
    final safeIntervals = [2, 7, 14];
    final interval = safeIntervals[random.nextInt(safeIntervals.length)];
    final tensionPitch =
        (highest.pitch + interval).clamp(0, 127).toInt();
    final tensionVelocity =
        min(highest.velocity + 10, 127);
    final newNote = Note(
      id: 'tech003_${_tensionNoteCounter++}',
      pitch: tensionPitch,
      startBeat: highest.startBeat,
      duration: highest.duration,
      velocity: tensionVelocity,
    );
    mutated.add(newNote);
    return mutated;
  }
}
