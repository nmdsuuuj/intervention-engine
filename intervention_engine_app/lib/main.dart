import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/chord_entry.dart';
import 'models/midi_track.dart';
import 'models/note.dart';
import 'models/section.dart';
import 'models/song.dart';
import 'views/arrangement_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const InterventionEngineApp());
}

class InterventionEngineApp extends StatelessWidget {
  const InterventionEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Intervention Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        textTheme: ThemeData(
          brightness: Brightness.dark,
        ).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: ArrangementView(song: _buildDemoSong()),
    );
  }
}

Song _buildDemoSong() {
  final MidiTrack drumsA = MidiTrack(
    name: 'Drums',
    notes: <Note>[
      const Note(pitch: 36, startTime: 0, duration: 1, velocity: 2),
      const Note(pitch: 38, startTime: 1, duration: 1, velocity: 3),
      const Note(pitch: 42, startTime: 0.5, duration: 0.5, velocity: 1),
      const Note(pitch: 46, startTime: 1.5, duration: 0.5, velocity: 1),
    ],
  );

  final MidiTrack bassA = MidiTrack(
    name: 'Bass',
    notes: <Note>[
      const Note(pitch: 36, startTime: 0, duration: 2, velocity: 2),
      const Note(pitch: 38, startTime: 2, duration: 2, velocity: 2),
      const Note(pitch: 41, startTime: 4, duration: 2, velocity: 3),
    ],
  );

  final MidiTrack melodyA = MidiTrack(
    name: 'Melody',
    notes: <Note>[
      const Note(pitch: 60, startTime: 0, duration: 0.5, velocity: 2),
      const Note(pitch: 62, startTime: 0.5, duration: 0.5, velocity: 2),
      const Note(pitch: 64, startTime: 1, duration: 1, velocity: 3),
      const Note(pitch: 67, startTime: 2, duration: 1, velocity: 2),
      const Note(pitch: 69, startTime: 3, duration: 1, velocity: 2),
    ],
  );

  final List<ChordEntry> chordsA = <ChordEntry>[
    const ChordEntry(chordName: 'Cmaj7', startTime: 0, lyric: 'ひかり'),
    const ChordEntry(chordName: 'Em7', startTime: 2, lyric: 'さす'),
    const ChordEntry(chordName: 'Fmaj7', startTime: 4),
    const ChordEntry(chordName: 'G7', startTime: 6, lyric: 'ここから'),
  ];

  final Section sectionA = Section(
    name: 'A-Melo',
    lengthInBars: 8,
    drums: drumsA,
    bass: bassA,
    melody: melodyA,
    chords: chordsA,
  );

  final Section sectionB = Section(
    name: 'B-Melo',
    lengthInBars: 8,
    drums: MidiTrack(
      name: 'Drums',
      notes: drumsA.notes
          .map((Note note) => note.copyWith(startTime: note.startTime + 8))
          .toList(),
    ),
    bass: MidiTrack(
      name: 'Bass',
      notes: <Note>[
        const Note(pitch: 43, startTime: 8, duration: 2, velocity: 2),
        const Note(pitch: 45, startTime: 10, duration: 2, velocity: 2),
        const Note(pitch: 47, startTime: 12, duration: 2, velocity: 3),
      ],
    ),
    melody: MidiTrack(
      name: 'Melody',
      notes: <Note>[
        const Note(pitch: 71, startTime: 8, duration: 0.5, velocity: 3),
        const Note(pitch: 69, startTime: 8.5, duration: 0.75, velocity: 2),
        const Note(pitch: 67, startTime: 9.5, duration: 0.5, velocity: 2),
        const Note(pitch: 64, startTime: 10, duration: 1.5, velocity: 1),
        const Note(pitch: 62, startTime: 12, duration: 1, velocity: 2),
      ],
    ),
    chords: <ChordEntry>[
      const ChordEntry(chordName: 'Am7', startTime: 8, lyric: '変わる'),
      const ChordEntry(chordName: 'D7', startTime: 10),
      const ChordEntry(chordName: 'Gmaj7', startTime: 12, lyric: '瞬間'),
      const ChordEntry(chordName: 'Cmaj7', startTime: 14),
    ],
  );

  final Section sectionBridge = Section(
    name: 'Bridge',
    lengthInBars: 4,
    drums: MidiTrack(name: 'Drums', notes: const <Note>[]),
    bass: MidiTrack(
      name: 'Bass',
      notes: const <Note>[
        Note(pitch: 40, startTime: 16, duration: 4, velocity: 1),
      ],
    ),
    melody: MidiTrack(
      name: 'Melody',
      notes: const <Note>[
        Note(pitch: 65, startTime: 16, duration: 2, velocity: 2),
        Note(pitch: 67, startTime: 18, duration: 2, velocity: 3),
      ],
    ),
    chords: const <ChordEntry>[
      ChordEntry(chordName: 'Fmaj7', startTime: 16),
      ChordEntry(chordName: 'G7', startTime: 18, lyric: 'ソラへ'),
    ],
  );

  return Song(bpm: 96, sections: <Section>[sectionA, sectionB, sectionBridge]);
}
