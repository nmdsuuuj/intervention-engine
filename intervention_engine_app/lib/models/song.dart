import 'package:intervention_engine_app/models/section.dart';

class Song {
  Song({required this.bpm, List<Section> sections = const <Section>[]})
    : sections = List<Section>.unmodifiable(sections);

  final double bpm;
  final List<Section> sections;

  Song copyWith({double? bpm, List<Section>? sections}) {
    return Song(bpm: bpm ?? this.bpm, sections: sections ?? this.sections);
  }
}
