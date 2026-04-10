class Chore {
  Chore({
    required this.choreId,
    required this.name,
    required this.difficulty,
    required this.cadence,
    required this.active,
    required this.createdAt,
    this.rewards = const {},
  });

  final String choreId;
  final String name;
  final String difficulty;
  final String cadence;
  final bool active;
  final DateTime createdAt;
  final Map<String, double> rewards;

  factory Chore.fromJson(Map<String, dynamic> json) => Chore(
        choreId: json['chore_id'] as String,
        name: json['name'] as String,
        difficulty: json['difficulty'] as String,
        cadence: json['cadence'] as String,
        active: json['active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
        rewards: (json['rewards'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
            {},
      );
}
