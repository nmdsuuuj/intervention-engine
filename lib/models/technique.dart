class Technique {
  const Technique({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
  });

  final String id;
  final String name;
  final String description;
  final String type;

  factory Technique.fromJson(Map<String, dynamic> json) {
    return Technique(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type,
      };
}
