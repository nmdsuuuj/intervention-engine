/// アプリ内で扱うノート（音符）データの最小表現。
class Note {
  const Note({
    required this.id,
    required this.pitch,
    required this.startBeat,
    required this.duration,
    required this.velocity,
  });

  /// ノートを一意に識別するID（UI/Undoの整合性に必須）
  final String id;

  /// MIDIノート番号（0〜127）
  final int pitch;

  /// 再生開始位置（拍単位）
  final double startBeat;

  /// ノート長（拍単位）
  final double duration;

  /// ベロシティ（0〜127）— UI側では3〜5段階へのマッピングを想定
  final int velocity;

  Note copyWith({
    String? id,
    int? pitch,
    double? startBeat,
    double? duration,
    int? velocity,
  }) {
    return Note(
      id: id ?? this.id,
      pitch: pitch ?? this.pitch,
      startBeat: startBeat ?? this.startBeat,
      duration: duration ?? this.duration,
      velocity: velocity ?? this.velocity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pitch': pitch,
        'startBeat': startBeat,
        'duration': duration,
        'velocity': velocity,
      };

  static Note fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      pitch: json['pitch'] as int,
      startBeat: (json['startBeat'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      velocity: json['velocity'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note &&
        other.id == id &&
        other.pitch == pitch &&
        other.startBeat == startBeat &&
        other.duration == duration &&
        other.velocity == velocity;
  }

  @override
  int get hashCode =>
      Object.hash(id, pitch, startBeat, duration, velocity);

  @override
  String toString() =>
      'Note(id: $id, pitch: $pitch, startBeat: $startBeat, duration: $duration, velocity: $velocity)';
}
