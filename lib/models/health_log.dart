class HealthLog {
  final String id;
  final String type; // "check_in" | "medication" | "sos" | "chat" | "anomaly"
  final DateTime timestamp;
  final int mood; // 1-5
  final int sleepQuality; // 1-5
  final Map<String, int> painLevel; // e.g. {"knee": 4, "general": 2}
  final String notes;
  final String aiSummary;
  final List<String> flags;

  const HealthLog({
    required this.id,
    required this.type,
    required this.timestamp,
    this.mood = 3,
    this.sleepQuality = 3,
    this.painLevel = const {},
    this.notes = '',
    this.aiSummary = '',
    this.flags = const [],
  });

  factory HealthLog.fromJson(Map<String, dynamic> json, {String? id}) {
    return HealthLog(
      id: id ?? json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'check_in',
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      mood: json['mood'] as int? ?? 3,
      sleepQuality: json['sleepQuality'] as int? ?? 3,
      painLevel: (json['painLevel'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
      notes: json['notes'] as String? ?? '',
      aiSummary: json['aiSummary'] as String? ?? '',
      flags: (json['flags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'mood': mood,
        'sleepQuality': sleepQuality,
        'painLevel': painLevel,
        'notes': notes,
        'aiSummary': aiSummary,
        'flags': flags,
      };

  HealthLog copyWith({
    String? id,
    String? type,
    DateTime? timestamp,
    int? mood,
    int? sleepQuality,
    Map<String, int>? painLevel,
    String? notes,
    String? aiSummary,
    List<String>? flags,
  }) {
    return HealthLog(
      id: id ?? this.id,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      mood: mood ?? this.mood,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      painLevel: painLevel ?? this.painLevel,
      notes: notes ?? this.notes,
      aiSummary: aiSummary ?? this.aiSummary,
      flags: flags ?? this.flags,
    );
  }
}
