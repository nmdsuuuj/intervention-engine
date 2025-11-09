class ChordEntry {
  const ChordEntry({
    required this.chordName,
    required this.startTime,
    this.lyric,
  }) : assert(startTime >= 0, 'startTime must be non-negative');

  final String chordName;
  final double startTime;
  final String? lyric;

  ChordEntry copyWith({String? chordName, double? startTime, String? lyric}) {
    return ChordEntry(
      chordName: chordName ?? this.chordName,
      startTime: startTime ?? this.startTime,
      lyric: lyric ?? this.lyric,
    );
  }
}
