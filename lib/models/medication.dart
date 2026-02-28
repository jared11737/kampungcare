class Medication {
  final String id;
  final String name;
  final String dosage;
  final List<String> times; // e.g. ["07:00", "19:00"]
  final String pillDescription;
  final String instructions;
  final String prescribedBy;
  final List<String> interactions;

  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    this.pillDescription = '',
    this.instructions = '',
    this.prescribedBy = '',
    this.interactions = const [],
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      times: (json['times'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      pillDescription: json['pillDescription'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      prescribedBy: json['prescribedBy'] as String? ?? '',
      interactions: (json['interactions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'times': times,
        'pillDescription': pillDescription,
        'instructions': instructions,
        'prescribedBy': prescribedBy,
        'interactions': interactions,
      };

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    List<String>? times,
    String? pillDescription,
    String? instructions,
    String? prescribedBy,
    List<String>? interactions,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      times: times ?? this.times,
      pillDescription: pillDescription ?? this.pillDescription,
      instructions: instructions ?? this.instructions,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      interactions: interactions ?? this.interactions,
    );
  }
}
