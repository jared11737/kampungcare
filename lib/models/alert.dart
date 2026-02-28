enum AlertType {
  missedCheckin,
  sos,
  patternAnomaly,
  missedMedication;

  String toJson() {
    switch (this) {
      case AlertType.missedCheckin:
        return 'missed_checkin';
      case AlertType.sos:
        return 'sos';
      case AlertType.patternAnomaly:
        return 'pattern_anomaly';
      case AlertType.missedMedication:
        return 'missed_medication';
    }
  }

  static AlertType fromJson(String value) {
    switch (value) {
      case 'missed_checkin':
        return AlertType.missedCheckin;
      case 'sos':
        return AlertType.sos;
      case 'pattern_anomaly':
        return AlertType.patternAnomaly;
      case 'missed_medication':
        return AlertType.missedMedication;
      default:
        return AlertType.missedCheckin;
    }
  }
}

enum AlertSeverity {
  yellow,
  red;

  String toJson() => name;

  static AlertSeverity fromJson(String value) {
    return AlertSeverity.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertSeverity.yellow,
    );
  }
}

enum AlertStatus {
  pending,
  acknowledged,
  resolved;

  String toJson() => name;

  static AlertStatus fromJson(String value) {
    return AlertStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AlertStatus.pending,
    );
  }
}

class Alert {
  final String id;
  final String elderlyUid;
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final AlertStatus status;
  final DateTime createdAt;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  const Alert({
    required this.id,
    required this.elderlyUid,
    required this.type,
    this.severity = AlertSeverity.yellow,
    required this.message,
    this.status = AlertStatus.pending,
    required this.createdAt,
    this.resolvedBy,
    this.resolvedAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json, {String? id}) {
    return Alert(
      id: id ?? json['id'] as String? ?? '',
      elderlyUid: json['elderlyUid'] as String? ?? '',
      type: AlertType.fromJson(json['type'] as String? ?? 'missed_checkin'),
      severity:
          AlertSeverity.fromJson(json['severity'] as String? ?? 'yellow'),
      message: json['message'] as String? ?? '',
      status:
          AlertStatus.fromJson(json['status'] as String? ?? 'pending'),
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      resolvedBy: json['resolvedBy'] as String?,
      resolvedAt: json['resolvedAt'] is String
          ? DateTime.tryParse(json['resolvedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'elderlyUid': elderlyUid,
        'type': type.toJson(),
        'severity': severity.toJson(),
        'message': message,
        'status': status.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'resolvedBy': resolvedBy,
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  Alert copyWith({
    String? id,
    String? elderlyUid,
    AlertType? type,
    AlertSeverity? severity,
    String? message,
    AlertStatus? status,
    DateTime? createdAt,
    String? resolvedBy,
    DateTime? resolvedAt,
  }) {
    return Alert(
      id: id ?? this.id,
      elderlyUid: elderlyUid ?? this.elderlyUid,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
