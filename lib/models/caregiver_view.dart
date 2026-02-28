class CaregiverView {
  final String currentStatus; // "green" | "yellow" | "red"
  final DateTime lastCheckIn;
  final int todayMedsTaken;
  final int todayMedsScheduled;
  final double weeklyMoodAvg;
  final List<String> activeConcerns;
  final String weeklySummary;

  const CaregiverView({
    this.currentStatus = 'green',
    required this.lastCheckIn,
    this.todayMedsTaken = 0,
    this.todayMedsScheduled = 0,
    this.weeklyMoodAvg = 3.0,
    this.activeConcerns = const [],
    this.weeklySummary = '',
  });

  factory CaregiverView.fromJson(Map<String, dynamic> json) {
    return CaregiverView(
      currentStatus: json['currentStatus'] as String? ?? 'green',
      lastCheckIn: json['lastCheckIn'] is String
          ? DateTime.parse(json['lastCheckIn'] as String)
          : DateTime.now(),
      todayMedsTaken: json['todayMedsTaken'] as int? ?? 0,
      todayMedsScheduled: json['todayMedsScheduled'] as int? ?? 0,
      weeklyMoodAvg:
          (json['weeklyMoodAvg'] as num?)?.toDouble() ?? 3.0,
      activeConcerns: (json['activeConcerns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      weeklySummary: json['weeklySummary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'currentStatus': currentStatus,
        'lastCheckIn': lastCheckIn.toIso8601String(),
        'todayMedsTaken': todayMedsTaken,
        'todayMedsScheduled': todayMedsScheduled,
        'weeklyMoodAvg': weeklyMoodAvg,
        'activeConcerns': activeConcerns,
        'weeklySummary': weeklySummary,
      };

  CaregiverView copyWith({
    String? currentStatus,
    DateTime? lastCheckIn,
    int? todayMedsTaken,
    int? todayMedsScheduled,
    double? weeklyMoodAvg,
    List<String>? activeConcerns,
    String? weeklySummary,
  }) {
    return CaregiverView(
      currentStatus: currentStatus ?? this.currentStatus,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      todayMedsTaken: todayMedsTaken ?? this.todayMedsTaken,
      todayMedsScheduled:
          todayMedsScheduled ?? this.todayMedsScheduled,
      weeklyMoodAvg: weeklyMoodAvg ?? this.weeklyMoodAvg,
      activeConcerns: activeConcerns ?? this.activeConcerns,
      weeklySummary: weeklySummary ?? this.weeklySummary,
    );
  }
}
