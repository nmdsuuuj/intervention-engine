import 'dart:collection';

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
    _setBusy(true);
    try {
      final list = await engine.getApplicableTechniques(
        selected,
        pianoRollController.contextType,
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
      _activeTechnique = technique;
      _originalSnapshot =
          pianoRollController.selectedNotes.map((note) => note.copyWith()).toList();
      final mutated =
          await engine.applyTechnique(_originalSnapshot!, technique.id);
      _previewNotes = mutated;
      pianoRollController.setPreviewNotes(mutated);
      await audioPreviewService.playLoop(mutated);
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  void cancelPreview() {
    if (_previewNotes == null) return;
    audioPreviewService.stop();
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
    audioPreviewService.stop();
    _previewNotes = null;
    _originalSnapshot = null;
    _activeTechnique = null;
    notifyListeners();
  }

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
