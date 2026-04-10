class Submission {
  Submission({
    required this.submissionId,
    required this.choreId,
    required this.memberId,
    required this.deviceId,
    required this.householdId,
    required this.completedAt,
    required this.approved,
    this.rejectionReason,
    this.notes,
  });

  final String submissionId;
  final String choreId;
  final String memberId;
  final String deviceId;
  final String householdId;
  final DateTime completedAt;
  final bool approved;
  final String? rejectionReason;
  final String? notes;

  factory Submission.fromJson(Map<String, dynamic> json) => Submission(
        submissionId: json['submission_id'] as String,
        choreId: json['chore_id'] as String,
        memberId: json['member_id'] as String,
        deviceId: json['device_id'] as String,
        householdId: json['household_id'] as String,
        completedAt: DateTime.parse(json['completed_at'] as String),
        approved: json['approved'] as bool,
        rejectionReason: json['rejection_reason'] as String?,
        notes: json['notes'] as String?,
      );
}
