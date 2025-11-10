import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

import '../models/note.dart';

/// `[ MUTATE ]` プレビュー用の簡易シーケンサー付きMIDI再生サービス。
class AudioPreviewService {
  AudioPreviewService({
    required String soundFontAsset,
    Duration tickInterval = const Duration(milliseconds: 10),
    int midiChannel = 0,
  })  : _soundFontAsset = soundFontAsset,
        _tickInterval = tickInterval,
        _midiChannel = midiChannel;

  final String _soundFontAsset;
  final Duration _tickInterval;
  final int _midiChannel;

  final FlutterMidiPro _midi = FlutterMidiPro();

  bool _initialized = false;
  bool _isLooping = false;
  Timer? _sequencerTimer;

  double _bpm = 120;
  double _beatDurationMs = 500; // 120 BPM の場合
  double _loopLengthMs = 0;
  double _positionMs = 0;

  final List<_ScheduledNote> _scheduledNotes = [];

  bool get isLooping => _isLooping;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final soundFontData = await rootBundle.load(_soundFontAsset);
      await _midi.prepare(sf2: soundFontData);
      _initialized = true;
    } catch (e) {
      // サウンドフォントが見つからない場合は初期化をスキップ
      print('Warning: Could not load sound font: $e');
      _initialized = true;
    }
  }

  Future<void> playLoop(
    List<Note> notes, {
    required double bpm,
  }) async {
    await init();
    stopLoop();
    if (notes.isEmpty) return;

    _bpm = bpm;
    _beatDurationMs = 60000 / max(_bpm, 1);
    _scheduledNotes
      ..clear()
      ..addAll(notes.map(_mapNote))
      ..sort((a, b) => a.startMs.compareTo(b.startMs));

    _loopLengthMs = _scheduledNotes.isEmpty
        ? _beatDurationMs * 4
        : _scheduledNotes
            .map((note) => note.endMs)
            .fold<double>(0, max);
    if (_loopLengthMs <= 0) {
      _loopLengthMs = _beatDurationMs * 4;
    }

    _positionMs = 0;
    _isLooping = true;

    _triggerInitialNotes();

    _sequencerTimer = Timer.periodic(_tickInterval, (timer) {
      if (!_isLooping) return;
      final previousPosition = _positionMs;
      _positionMs += _tickInterval.inMilliseconds;

      if (_positionMs >= _loopLengthMs) {
        final overflow = _positionMs - _loopLengthMs;
        _processRange(previousPosition, _loopLengthMs);
        _stopActiveNotes();
        _positionMs = overflow;
        _resetNoteStates();
        _processRange(0, _positionMs);
      } else {
        _processRange(previousPosition, _positionMs);
      }
    });
  }

  void stopLoop() {
    if (_sequencerTimer == null && !_isLooping) return;
    _sequencerTimer?.cancel();
    _sequencerTimer = null;

    _stopActiveNotes();
    _resetNoteStates();

    _isLooping = false;
    _positionMs = 0;
    _scheduledNotes.clear();
  }

  _ScheduledNote _mapNote(Note note) {
    final startMs = note.startBeat * _beatDurationMs;
    final endMs = (note.startBeat + note.duration) * _beatDurationMs;
    return _ScheduledNote(
      note: note,
      startMs: startMs,
      endMs: endMs,
    );
  }

  void _triggerInitialNotes() {
    const epsilon = 0.0001;
    for (final event in _scheduledNotes) {
      if (!event.isActive && event.startMs.abs() < epsilon) {
        _noteOn(event);
      }
    }
  }

  void _processRange(double startMs, double endMs) {
    for (final event in _scheduledNotes) {
      if (!event.isActive && _isInRange(event.startMs, startMs, endMs)) {
        _noteOn(event);
      }
      if (event.isActive && _isInRange(event.endMs, startMs, endMs)) {
        _noteOff(event);
      }
    }
  }

  bool _isInRange(double value, double start, double end) {
    if (end < start) return value >= start || value < end;
    return value >= start && value < end;
  }

  void _noteOn(_ScheduledNote event) {
    try {
      _midi.playMidiNote(
        midi: event.note.pitch,
        velocity: event.note.velocity,
        channel: _midiChannel,
      );
      event.isActive = true;
    } catch (e) {
      // MIDI再生エラーを無視
      print('Warning: Could not play MIDI note: $e');
    }
  }

  void _noteOff(_ScheduledNote event) {
    try {
      _midi.stopMidiNote(
        midi: event.note.pitch,
        channel: _midiChannel,
      );
      event.isActive = false;
    } catch (e) {
      // MIDI停止エラーを無視
      print('Warning: Could not stop MIDI note: $e');
    }
  }

  void _stopActiveNotes() {
    for (final event in _scheduledNotes) {
      if (event.isActive) {
        try {
          _midi.stopMidiNote(
            midi: event.note.pitch,
            channel: _midiChannel,
          );
          event.isActive = false;
        } catch (e) {
          // MIDI停止エラーを無視
          print('Warning: Could not stop MIDI note: $e');
        }
      }
    }
  }

  void _resetNoteStates() {
    for (final event in _scheduledNotes) {
      event.isActive = false;
    }
  }

  /// 単一のノートを再生（再生ヘッド用）
  void playNote(Note note) {
    try {
      _midi.playMidiNote(
        midi: note.pitch,
        velocity: note.velocity,
        channel: _midiChannel,
      );
    } catch (e) {
      print('Warning: Could not play MIDI note: $e');
    }
  }

  /// 単一のノートを停止（再生ヘッド用）
  void stopNote(Note note) {
    try {
      _midi.stopMidiNote(
        midi: note.pitch,
        channel: _midiChannel,
      );
    } catch (e) {
      print('Warning: Could not stop MIDI note: $e');
    }
  }
}

class _ScheduledNote {
  _ScheduledNote({
    required this.note,
    required this.startMs,
    required this.endMs,
  });

  final Note note;
  final double startMs;
  final double endMs;
  bool isActive = false;
}
