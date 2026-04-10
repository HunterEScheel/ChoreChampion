class Household {
  Household({
    required this.householdId,
    required this.name,
    required this.timezone,
    required this.createdAt,
  });

  final String householdId;
  final String name;
  final String timezone;
  final DateTime createdAt;

  factory Household.fromJson(Map<String, dynamic> json) => Household(
        householdId: json['household_id'] as String,
        name: json['name'] as String,
        timezone: json['timezone'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class Member {
  Member({
    required this.memberId,
    required this.householdId,
    required this.name,
  });

  final String memberId;
  final String householdId;
  final String name;

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        memberId: json['member_id'] as String,
        householdId: json['household_id'] as String,
        name: json['name'] as String,
      );
}

class HouseholdMeResponse {
  HouseholdMeResponse({required this.household, required this.members});

  final Household household;
  final List<Member> members;

  factory HouseholdMeResponse.fromJson(Map<String, dynamic> json) =>
      HouseholdMeResponse(
        household: Household.fromJson(json['household'] as Map<String, dynamic>),
        members: (json['members'] as List<dynamic>)
            .map((e) => Member.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BootstrapResponse {
  BootstrapResponse({
    required this.household,
    required this.device,
    required this.jwt,
  });

  final Household household;
  final Device device;
  final String jwt;

  factory BootstrapResponse.fromJson(Map<String, dynamic> json) =>
      BootstrapResponse(
        household: Household.fromJson(json['household'] as Map<String, dynamic>),
        device: Device.fromJson(json['device'] as Map<String, dynamic>),
        jwt: json['jwt'] as String,
      );
}

class Device {
  Device({
    required this.deviceId,
    required this.householdId,
    this.deviceName,
    required this.isAdmin,
    required this.createdAt,
  });

  final String deviceId;
  final String householdId;
  final String? deviceName;
  final bool isAdmin;
  final DateTime createdAt;

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        deviceId: json['device_id'] as String,
        householdId: json['household_id'] as String,
        deviceName: json['device_name'] as String?,
        isAdmin: json['is_admin'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
