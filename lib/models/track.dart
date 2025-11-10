import 'package:collection/collection.dart';

import 'note.dart';

/// トラックごとのメタデータとノートを保持するモデル。
class Track {
  const Track({
    required this.id,
    required this.name,
    required this.contextType,
    required this.notes,
  });

  final String id;
  final String name;
  final String contextType;
  final List<Note> notes;

  Track copyWith({
    String? id,
    String? name,
    String? contextType,
    List<Note>? notes,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      contextType: contextType ?? this.contextType,
      notes: notes != null
          ? List<Note>.from(notes)
          : List<Note>.from(this.notes),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Track &&
        other.id == id &&
        other.name == name &&
        other.contextType == contextType &&
        const DeepCollectionEquality().equals(other.notes, notes);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        contextType,
        const DeepCollectionEquality().hash(notes),
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contextType': contextType,
      'notes': notes.map((note) => note.toJson()).toList(),
    };
  }

  static Track fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      name: json['name'] as String,
      contextType: json['contextType'] as String,
      notes: (json['notes'] as List)
          .map((n) => Note.fromJson(n as Map<String, dynamic>))
          .toList(),
    );
  }
}
