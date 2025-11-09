import 'package:intervention_engine_app/models/chord_entry.dart';
import 'package:intervention_engine_app/models/midi_track.dart';

class Section {
  Section({
    required this.name,
    required this.lengthInBars,
    required this.drums,
    required this.bass,
    required this.melody,
    List<ChordEntry> chords = const <ChordEntry>[],
  }) : assert(lengthInBars > 0, 'lengthInBars must be greater than zero'),
       chords = List<ChordEntry>.unmodifiable(chords);

  final String name;
  final int lengthInBars;

  final MidiTrack drums;
  final MidiTrack bass;
  final MidiTrack melody;
  final List<ChordEntry> chords;

  Section copyWith({
    String? name,
    int? lengthInBars,
    MidiTrack? drums,
    MidiTrack? bass,
    MidiTrack? melody,
    List<ChordEntry>? chords,
  }) {
    return Section(
      name: name ?? this.name,
      lengthInBars: lengthInBars ?? this.lengthInBars,
      drums: drums ?? this.drums,
      bass: bass ?? this.bass,
      melody: melody ?? this.melody,
      chords: chords ?? this.chords,
    );
  }
}
