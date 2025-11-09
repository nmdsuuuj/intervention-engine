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

  Future<void> loadTechniques() async {
    if (_cachedTechniques != null) return;
    final raw = await _bundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    _cachedTechniques = decoded
        .map((entry) => Technique.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<Technique>> getApplicableTechniques(
    List<Note> selectedNotes,
    String contextType,
  ) async {
    await loadTechniques();
    final cache = _cachedTechniques ?? const [];
    if (contextType.isEmpty) {
      return cache;
    }
    return cache
        .where((technique) => technique.type == contextType)
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
}
