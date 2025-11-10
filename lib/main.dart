import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controllers/mutate_workflow_controller.dart';
import 'models/note.dart';
import 'services/audio_preview_service.dart';
import 'services/intervention_engine.dart';
import 'state/piano_roll_controller.dart';
import 'state/song_state.dart';
import 'state/undo_manager.dart';
import 'ui/screens/track_view_screen.dart';
import 'models/track.dart';

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
    final initialTracks = _createInitialTracks();
    final defaultTrack = initialTracks.first;
    _pianoRollController = PianoRollController(
      trackId: defaultTrack.id,
      contextType: defaultTrack.contextType,
    );
    _songState = SongState(
      initialTracks: initialTracks,
      bpm: 120,
    );
    _undoManager = UndoManager();
    _engine = InterventionEngine();
    _audioPreviewService = AudioPreviewService(
      soundFontAsset: 'assets/sounds/tim_gm.sf2',
    );
    _mutateController = MutateWorkflowController(
      pianoRollController: _pianoRollController,
      songState: _songState,
      engine: _engine,
      undoManager: _undoManager,
      audioPreviewService: _audioPreviewService,
    );

    // 再生サービスをSongStateに設定
    _songState.setAudioService(_audioPreviewService);

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
          onBackPressed: () {
            // TODO: 前の画面に戻る機能を実装
            Navigator.of(context).pop();
          },
          onSavePressed: () => _handleSave(context),
          onHumPressed: () => _handleHum(context),
        ),
      ),
    );
  }

  List<Track> _createInitialTracks() {
    return [
      Track(
        id: 'drums',
        name: 'Drums',
        contextType: 'drum_groove',
        notes: const [
          Note(id: 'd1', pitch: 36, startBeat: 0, duration: 0.5, velocity: 100),
          Note(id: 'd2', pitch: 38, startBeat: 1, duration: 0.5, velocity: 100),
          Note(id: 'd3', pitch: 42, startBeat: 2, duration: 0.5, velocity: 96),
          Note(id: 'd4', pitch: 38, startBeat: 3, duration: 0.5, velocity: 96),
        ],
      ),
      Track(
        id: 'bass',
        name: 'Bass',
        contextType: 'bass_melody',
        notes: const [
          Note(id: 'b1', pitch: 36, startBeat: 0, duration: 1, velocity: 96),
          Note(id: 'b2', pitch: 43, startBeat: 1, duration: 1, velocity: 96),
          Note(id: 'b3', pitch: 48, startBeat: 2, duration: 1, velocity: 96),
          Note(id: 'b4', pitch: 55, startBeat: 3, duration: 1, velocity: 96),
        ],
      ),
      Track(
        id: 'chords',
        name: 'Chords',
        contextType: 'chord_mutate',
        notes: const [
          Note(id: 'c1', pitch: 60, startBeat: 0, duration: 2, velocity: 90),
          Note(id: 'c2', pitch: 64, startBeat: 0, duration: 2, velocity: 90),
          Note(id: 'c3', pitch: 67, startBeat: 0, duration: 2, velocity: 90),
        ],
      ),
    ];
  }

  Future<void> _handleSave(BuildContext context) async {
    try {
      final jsonData = _songState.toJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      
      // クリップボードにコピー（実際のアプリではファイル保存に変更）
      await Clipboard.setData(ClipboardData(text: jsonString));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleHum(BuildContext context) async {
    // TODO: 鼻歌録音機能を実装
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('HUM feature coming soon'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
