enum MedicationStatus {
  taken,
  missed,
  late,
  wrongPill;

  String toJson() => name;

  static MedicationStatus fromJson(String value) {
    // Handle snake_case from Firestore ("wrong_pill")
    final normalized = value.replaceAll('_', '').toLowerCase();
    return MedicationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized ||
          e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MedicationStatus.missed,
    );
  }
}

class MedicationLog {
  final String id;
  final String medicationId;
  final String scheduledTime; // e.g. "07:00"
  final DateTime? takenTime;
  final MedicationStatus status;
  final bool photoVerified;
  final Map<String, dynamic>? geminiVerification;

  const MedicationLog({
    required this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.takenTime,
    this.status = MedicationStatus.missed,
    this.photoVerified = false,
    this.geminiVerification,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json, {String? id}) {
    return MedicationLog(
      id: id ?? json['id'] as String? ?? '',
      medicationId: json['medicationId'] as String? ?? '',
      scheduledTime: json['scheduledTime'] as String? ?? '',
      takenTime: json['takenTime'] is String
          ? DateTime.tryParse(json['takenTime'] as String)
          : null,
      status:
          MedicationStatus.fromJson(json['status'] as String? ?? 'missed'),
      photoVerified: json['photoVerified'] as bool? ?? false,
      geminiVerification:
          json['geminiVerification'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicationId': medicationId,
        'scheduledTime': scheduledTime,
        'takenTime': takenTime?.toIso8601String(),
        'status': status.toJson(),
        'photoVerified': photoVerified,
        'geminiVerification': geminiVerification,
      };

  MedicationLog copyWith({
    String? id,
    String? medicationId,
    String? scheduledTime,
    DateTime? takenTime,
    MedicationStatus? status,
    bool? photoVerified,
    Map<String, dynamic>? geminiVerification,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      status: status ?? this.status,
      photoVerified: photoVerified ?? this.photoVerified,
      geminiVerification: geminiVerification ?? this.geminiVerification,
    );
  }
}
