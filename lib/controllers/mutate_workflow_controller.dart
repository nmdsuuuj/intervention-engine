import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../models/technique.dart';
import '../services/audio_preview_service.dart';
import '../services/intervention_engine.dart';
import '../state/piano_roll_controller.dart';
import '../state/song_state.dart';
import '../state/undo_manager.dart';

/// `[ MUTATE ]` ボタンのワークフロー全体を統括するコントローラ。
class MutateWorkflowController extends ChangeNotifier {
  MutateWorkflowController({
    required this.pianoRollController,
    required this.songState,
    required this.engine,
    required this.undoManager,
    required this.audioPreviewService,
  }) {
    pianoRollController.addListener(_handleSelectionChanged);
  }

  final PianoRollController pianoRollController;
  final SongState songState;
  final InterventionEngine engine;
  final UndoManager undoManager;
  final AudioPreviewService audioPreviewService;

  final List<Technique> _suggestions = [];
  Technique? _activeTechnique;
  List<Note>? _previewNotes;
  List<Note>? _originalSnapshot;
  bool _isBusy = false;

  bool get isMutateEnabled => pianoRollController.hasSelection && !_isBusy;

  bool get hasPreview => _previewNotes != null;

  Technique? get activeTechnique => _activeTechnique;

  UnmodifiableListView<Technique> get suggestions =>
      UnmodifiableListView(_suggestions);

  bool get isBusy => _isBusy;

  bool get canCopy =>
      pianoRollController.isSelectToolActive &&
      pianoRollController.hasSelection &&
      !_isBusy;

  bool get canPaste =>
      pianoRollController.isSelectToolActive &&
      songState.hasClipboard &&
      !_isBusy;

  bool get canDelete => canCopy;

  Note? _resizeOriginal;
  Note? _resizeWorking;

  void _handleSelectionChanged() {
    notifyListeners();
  }

  Future<List<Technique>> fetchTechniquesForSelection() async {
    final selected = pianoRollController.selectedNotes;
    if (selected.isEmpty) {
      _suggestions
        ..clear();
      notifyListeners();
      return const [];
    }
    final track = songState.trackById(pianoRollController.trackId);
    if (track == null) {
      _suggestions
        ..clear();
      notifyListeners();
      return const [];
    }
    if (pianoRollController.contextType != track.contextType) {
      pianoRollController.contextType = track.contextType;
    }
    _setBusy(true);
    try {
      final list = await engine.getApplicableTechniques(
        selected,
        contextType: track.contextType,
      );
      _suggestions
        ..clear()
        ..addAll(list);
      return suggestions;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> previewTechnique(Technique technique) async {
    if (!pianoRollController.hasSelection) return;
    _setBusy(true);
    try {
      audioPreviewService.stopLoop();
      _activeTechnique = technique;
      _originalSnapshot =
          pianoRollController.selectedNotes.map((note) => note.copyWith()).toList();
      final mutated = await engine.applyTechnique(
        _originalSnapshot!,
        technique.id,
        bpm: songState.bpm,
      );
      _previewNotes = mutated;
      pianoRollController.setPreviewNotes(mutated);
      await audioPreviewService.playLoop(
        mutated,
        bpm: songState.bpm,
      );
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  void cancelPreview() {
    audioPreviewService.stopLoop();
    if (_previewNotes == null) return;
    _previewNotes = null;
    _activeTechnique = null;
    pianoRollController.clearPreviewNotes();
    notifyListeners();
  }

  void applyPreview() {
    if (_previewNotes == null ||
        _originalSnapshot == null ||
        _activeTechnique == null) {
      return;
    }
    final trackId = pianoRollController.trackId;
    final original = _originalSnapshot!;
    final mutated = _previewNotes!;

    songState.replaceNotes(
      trackId,
      removeTargets: original,
      insertNotes: mutated,
    );

    undoManager.push(
      UndoEntry(
        description: '[MUTATE] ${_activeTechnique!.name}',
        undo: () {
          songState.replaceNotes(
            trackId,
            removeTargets: mutated,
            insertNotes: original,
          );
          pianoRollController.updateSelection(original);
        },
        redo: () {
          songState.replaceNotes(
            trackId,
            removeTargets: original,
            insertNotes: mutated,
          );
          pianoRollController.updateSelection(mutated);
        },
      ),
    );

    pianoRollController.updateSelection(mutated);
    pianoRollController.clearPreviewNotes();
    audioPreviewService.stopLoop();
    _previewNotes = null;
    _originalSnapshot = null;
    _activeTechnique = null;
    notifyListeners();
  }

  void copySelection() {
    if (!canCopy) return;
    final selection = pianoRollController.selectedNotes
        .map((note) => note.copyWith())
        .toList(growable: false);
    songState.copyToClipboard(selection);
  }

  void cutSelection() {
    if (!canCopy) return;
    final trackId = pianoRollController.trackId;
    final selection = pianoRollController.selectedNotes
        .map((note) => note.copyWith())
        .toList(growable: false);
    final removed = songState.cutNotes(trackId, selection);
    if (removed.isEmpty) return;
    final removedForUndo =
        removed.map((note) => note.copyWith()).toList(growable: false);
    pianoRollController.clearSelection();
    undoManager.push(
      UndoEntry(
        description: '[Cut] ${removed.length} notes',
        undo: () {
          final restored = songState.addNotes(trackId, removedForUndo);
          pianoRollController.updateSelection(
            restored.isNotEmpty ? restored : removedForUndo,
          );
        },
        redo: () {
          songState.removeNotes(trackId, removedForUndo);
          pianoRollController.clearSelection();
        },
      ),
    );
  }

  void deleteSelection() {
    if (!canDelete) return;
    final trackId = pianoRollController.trackId;
    final selection = pianoRollController.selectedNotes
        .map((note) => note.copyWith())
        .toList(growable: false);
    final removed = songState.removeNotes(trackId, selection);
    if (removed.isEmpty) return;
    final removedForUndo =
        removed.map((note) => note.copyWith()).toList(growable: false);
    pianoRollController.clearSelection();
    undoManager.push(
      UndoEntry(
        description: '[Delete] ${removed.length} notes',
        undo: () {
          final restored = songState.addNotes(trackId, removedForUndo);
          pianoRollController.updateSelection(
            restored.isNotEmpty ? restored : removedForUndo,
          );
        },
        redo: () {
          songState.removeNotes(trackId, removedForUndo);
          pianoRollController.clearSelection();
        },
      ),
    );
  }

  void pasteClipboard() {
    if (!canPaste) return;
    final trackId = pianoRollController.trackId;
    final targetBeat =
        pianoRollController.snapBeat(songState.playheadBeat);
    final pasted = songState.pasteClipboard(trackId, targetBeat);
    if (pasted.isEmpty) return;
    final pastedForUndo =
        pasted.map((note) => note.copyWith()).toList(growable: false);
    pianoRollController.updateSelection(pasted);
    undoManager.push(
      UndoEntry(
        description: '[Paste] ${pasted.length} notes',
        undo: () {
          songState.removeNotes(trackId, pastedForUndo);
          pianoRollController.clearSelection();
        },
        redo: () {
          final restored = songState.addNotes(trackId, pastedForUndo);
          pianoRollController.updateSelection(
            restored.isNotEmpty ? restored : pastedForUndo,
          );
        },
      ),
    );
  }

  void createNoteAt(double rawBeat, int pitch, {double defaultLength = 1.0}) {
    if (!_isToolWritable) return;
    final trackId = pianoRollController.trackId;
    final snappedStart = pianoRollController.snapBeat(rawBeat);
    double snappedEnd = pianoRollController.snapBeat(snappedStart + defaultLength);
    if ((snappedEnd - snappedStart).abs() < 1e-3) {
      snappedEnd = snappedStart + defaultLength;
    }
    final duration = math.max(0.125, snappedEnd - snappedStart);
    final safePitch = math.max(0, math.min(127, pitch));
    final newNote = Note(
      id: songState.generateNoteId(),
      pitch: safePitch,
      startBeat: snappedStart,
      duration: duration,
      velocity: 96,
    );
    final inserted = songState.addNotes(trackId, [newNote]);
    final stored = inserted.isNotEmpty ? inserted.first : newNote;
    pianoRollController.updateSelection([stored]);
    undoManager.push(
      UndoEntry(
        description: '[Draw] Add note',
        undo: () {
          songState.removeNotes(trackId, [stored]);
          pianoRollController.clearSelection();
        },
        redo: () {
          final restored = songState.addNotes(trackId, [stored]);
          final redoNote = restored.isNotEmpty ? restored.first : stored;
          pianoRollController.updateSelection([redoNote]);
        },
      ),
    );
  }

  void startNoteResize(Note note) {
    if (!_isToolWritable) return;
    _resizeOriginal = note.copyWith();
    _resizeWorking = note.copyWith();
  }

  Note? updateNoteResize(Note currentReference, double rawEndBeat) {
    if (!_isToolWritable || _resizeOriginal == null) return null;
    final snappedEnd = pianoRollController.snapBeat(rawEndBeat);
    double newDuration = math.max(
      0.125,
      snappedEnd - _resizeOriginal!.startBeat,
    );
    if ((newDuration - _resizeOriginal!.duration).abs() < 1e-3) {
      return _resizeWorking;
    }
    final updated = _resizeOriginal!.copyWith(duration: newDuration);
    final trackId = pianoRollController.trackId;
    songState.replaceNotes(
      trackId,
      removeTargets: [currentReference],
      insertNotes: [updated],
    );
    _resizeWorking = updated;
    pianoRollController.updateSelection([updated]);
    return updated;
  }

  void endNoteResize(Note finalReference) {
    if (_resizeOriginal == null || _resizeWorking == null) {
      _resizeOriginal = null;
      _resizeWorking = null;
      return;
    }
    final original = _resizeOriginal!;
    final current = _resizeWorking!;
    _resizeOriginal = null;
    _resizeWorking = null;
    if ((current.duration - original.duration).abs() < 1e-6 &&
        (current.startBeat - original.startBeat).abs() < 1e-6) {
      return;
    }
    final trackId = pianoRollController.trackId;
    undoManager.push(
      UndoEntry(
        description: '[Draw] Resize note',
        undo: () {
          songState.replaceNotes(
            trackId,
            removeTargets: [current],
            insertNotes: [original],
          );
          pianoRollController.updateSelection([original]);
        },
        redo: () {
          songState.replaceNotes(
            trackId,
            removeTargets: [original],
            insertNotes: [current],
          );
          pianoRollController.updateSelection([current]);
        },
      ),
    );
  }

  bool get _isToolWritable => pianoRollController.isDrawToolActive && !_isBusy;

  void _setBusy(bool value) {
    if (_isBusy == value) return;
    _isBusy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    pianoRollController.removeListener(_handleSelectionChanged);
    super.dispose();
  }
}
