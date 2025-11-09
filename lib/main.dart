import 'package:flutter/material.dart';

import 'controllers/mutate_workflow_controller.dart';
import 'models/note.dart';
import 'services/audio_preview_service.dart';
import 'services/intervention_engine.dart';
import 'state/piano_roll_controller.dart';
import 'state/song_state.dart';
import 'state/undo_manager.dart';
import 'ui/screens/track_view_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InterventionEngineApp());
}

class InterventionEngineApp extends StatefulWidget {
  const InterventionEngineApp({super.key});

  @override
  State<InterventionEngineApp> createState() => _InterventionEngineAppState();
}

class _InterventionEngineAppState extends State<InterventionEngineApp> {
  late final PianoRollController _pianoRollController;
  late final SongState _songState;
  late final UndoManager _undoManager;
  late final MutateWorkflowController _mutateController;
  late final InterventionEngine _engine;
  late final AudioPreviewService _audioPreviewService;

  @override
  void initState() {
    super.initState();
    _pianoRollController = PianoRollController(
      trackId: 'bass',
      contextType: 'bass_melody',
    );
    _songState = SongState(
      initialTracks: {
        'bass': _createInitialNotes(),
      },
      bpm: 120,
    );
    _undoManager = UndoManager();
    _engine = InterventionEngine();
    _audioPreviewService = AudioPreviewService(
      soundFontAsset: 'assets/sounds/placeholder.sf2',
    );
    _mutateController = MutateWorkflowController(
      pianoRollController: _pianoRollController,
      songState: _songState,
      engine: _engine,
      undoManager: _undoManager,
      audioPreviewService: _audioPreviewService,
    );

    Future.microtask(() => _audioPreviewService.init());
  }

  @override
  void dispose() {
    _audioPreviewService.stopLoop();
    _mutateController.dispose();
    _pianoRollController.dispose();
    _songState.dispose();
    _undoManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intervention Engine Prototype',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: TrackViewScreen(
          mutateController: _mutateController,
          pianoRollController: _pianoRollController,
          songState: _songState,
          undoManager: _undoManager,
        ),
      ),
    );
  }

  List<Note> _createInitialNotes() {
    return [
      const Note(id: 'n1', pitch: 36, startBeat: 0, duration: 1, velocity: 96),
      const Note(id: 'n2', pitch: 43, startBeat: 1, duration: 1, velocity: 96),
      const Note(id: 'n3', pitch: 48, startBeat: 2, duration: 1, velocity: 96),
      const Note(id: 'n4', pitch: 55, startBeat: 3, duration: 1, velocity: 96),
    ];
  }
}
