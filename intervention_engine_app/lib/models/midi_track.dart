import 'package:intervention_engine_app/models/note.dart';

class MidiTrack {
  MidiTrack({required this.name, List<Note> notes = const <Note>[]})
    : notes = List<Note>.unmodifiable(notes);

  final String name;
  final List<Note> notes;

  MidiTrack copyWith({String? name, List<Note>? notes}) {
    return MidiTrack(name: name ?? this.name, notes: notes ?? this.notes);
  }
}
