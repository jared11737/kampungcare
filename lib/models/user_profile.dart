enum UserRole {
  elderly,
  caregiver,
  buddy;

  String toJson() => name;

  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.elderly,
    );
  }
}

class Condition {
  final String name;
  final String since;
  final String severity;

  const Condition({
    required this.name,
    required this.since,
    required this.severity,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      name: json['name'] as String? ?? '',
      since: json['since'] as String? ?? '',
      severity: json['severity'] as String? ?? 'managed',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'since': since,
        'severity': severity,
      };

  Condition copyWith({
    String? name,
    String? since,
    String? severity,
  }) {
    return Condition(
      name: name ?? this.name,
      since: since ?? this.since,
      severity: severity ?? this.severity,
    );
  }
}

class UserProfile {
  final String uid;
  final String name;
  final int age;
  final String phone;
  final String language;
  final String address;
  final String bloodType;
  final List<String> allergies;
  final String preferredHospital;
  final String emergencyNote;
  final UserRole role;
  final List<Condition> conditions;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.age,
    required this.phone,
    this.language = 'ms',
    this.address = '',
    this.bloodType = '',
    this.allergies = const [],
    this.preferredHospital = '',
    this.emergencyNote = '',
    this.role = UserRole.elderly,
    this.conditions = const [],
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, {String? uid}) {
    return UserProfile(
      uid: uid ?? json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      phone: json['phone'] as String? ?? '',
      language: json['language'] as String? ?? 'ms',
      address: json['address'] as String? ?? '',
      bloodType: json['bloodType'] as String? ?? '',
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      preferredHospital: json['preferredHospital'] as String? ?? '',
      emergencyNote: json['emergencyNote'] as String? ?? '',
      role: UserRole.fromJson(json['role'] as String? ?? 'elderly'),
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((e) => Condition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'age': age,
        'phone': phone,
        'language': language,
        'address': address,
        'bloodType': bloodType,
        'allergies': allergies,
        'preferredHospital': preferredHospital,
        'emergencyNote': emergencyNote,
        'role': role.toJson(),
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  UserProfile copyWith({
    String? uid,
    String? name,
    int? age,
    String? phone,
    String? language,
    String? address,
    String? bloodType,
    List<String>? allergies,
    String? preferredHospital,
    String? emergencyNote,
    UserRole? role,
    List<Condition>? conditions,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      language: language ?? this.language,
      address: address ?? this.address,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      preferredHospital: preferredHospital ?? this.preferredHospital,
      emergencyNote: emergencyNote ?? this.emergencyNote,
      role: role ?? this.role,
      conditions: conditions ?? this.conditions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
