class CareContact {
  final String uid;
  final String name;
  final String relation;
  final String phone;
  final String? distance; // e.g. "50m" for buddies

  const CareContact({
    required this.uid,
    required this.name,
    required this.relation,
    required this.phone,
    this.distance,
  });

  factory CareContact.fromJson(Map<String, dynamic> json) {
    return CareContact(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      distance: json['distance'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'relation': relation,
        'phone': phone,
        if (distance != null) 'distance': distance,
      };

  CareContact copyWith({
    String? uid,
    String? name,
    String? relation,
    String? phone,
    String? distance,
  }) {
    return CareContact(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      phone: phone ?? this.phone,
      distance: distance ?? this.distance,
    );
  }
}

class CareNetwork {
  final List<CareContact> caregivers;
  final List<CareContact> buddies;
  final List<String> escalationOrder;

  const CareNetwork({
    this.caregivers = const [],
    this.buddies = const [],
    this.escalationOrder = const ['buddy', 'caregiver', 'emergency_services'],
  });

  factory CareNetwork.fromJson(Map<String, dynamic> json) {
    return CareNetwork(
      caregivers: (json['caregivers'] as List<dynamic>?)
              ?.map((e) => CareContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      buddies: (json['buddies'] as List<dynamic>?)
              ?.map((e) => CareContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      escalationOrder: (json['escalationOrder'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          ['buddy', 'caregiver', 'emergency_services'],
    );
  }

  Map<String, dynamic> toJson() => {
        'caregivers': caregivers.map((c) => c.toJson()).toList(),
        'buddies': buddies.map((b) => b.toJson()).toList(),
        'escalationOrder': escalationOrder,
      };

  CareNetwork copyWith({
    List<CareContact>? caregivers,
    List<CareContact>? buddies,
    List<String>? escalationOrder,
  }) {
    return CareNetwork(
      caregivers: caregivers ?? this.caregivers,
      buddies: buddies ?? this.buddies,
      escalationOrder: escalationOrder ?? this.escalationOrder,
    );
  }
}
