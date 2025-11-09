class Note {
  const Note({
    required this.pitch,
    required this.startTime,
    required this.duration,
    required this.velocity,
  }) : assert(pitch >= 0 && pitch <= 127, 'pitch must be between 0 and 127'),
       assert(startTime >= 0, 'startTime must be non-negative'),
       assert(duration >= 0, 'duration must be non-negative'),
       assert(velocity >= 0, 'velocity must be non-negative');

  /// MIDIノート番号（0-127）
  final int pitch;

  /// ノート開始位置（拍単位）
  final double startTime;

  /// ノート長さ（拍単位）
  final double duration;

  /// シンプルなベロシティ段階（docs/03に準拠）
  final int velocity;

  Note copyWith({
    int? pitch,
    double? startTime,
    double? duration,
    int? velocity,
  }) {
    return Note(
      pitch: pitch ?? this.pitch,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      velocity: velocity ?? this.velocity,
    );
  }
}
