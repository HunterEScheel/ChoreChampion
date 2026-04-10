class MemberRewardTotals {
  MemberRewardTotals({
    required this.memberId,
    required this.name,
    required this.totals,
  });

  final String memberId;
  final String name;
  final Map<String, double> totals;

  factory MemberRewardTotals.fromJson(Map<String, dynamic> json) =>
      MemberRewardTotals(
        memberId: json['member_id'] as String,
        name: json['name'] as String,
        totals: (json['totals'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
}

class RewardCategory {
  RewardCategory({
    required this.rewardCategoryId,
    required this.householdId,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  final String rewardCategoryId;
  final String householdId;
  final String name;
  final String type;
  final DateTime createdAt;

  factory RewardCategory.fromJson(Map<String, dynamic> json) => RewardCategory(
        rewardCategoryId: json['reward_category_id'] as String,
        householdId: json['household_id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class DifficultyMapping {
  DifficultyMapping({
    required this.id,
    required this.householdId,
    required this.difficulty,
    required this.rewardCategoryId,
    required this.value,
    required this.createdAt,
  });

  final String id;
  final String householdId;
  final String difficulty;
  final String rewardCategoryId;
  final double value;
  final DateTime createdAt;

  factory DifficultyMapping.fromJson(Map<String, dynamic> json) =>
      DifficultyMapping(
        id: json['id'] as String,
        householdId: json['household_id'] as String,
        difficulty: json['difficulty'] as String,
        rewardCategoryId: json['reward_category_id'] as String,
        value: (json['value'] as num).toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toUpsertJson() => {
        'difficulty': difficulty,
        'reward_category_id': rewardCategoryId,
        'value': value,
      };
}
