class AiTopic {
  final DateTime date;
  final String topic;

  const AiTopic({
    required this.date,
    required this.topic,
  });

  factory AiTopic.fromJson(Map<String, dynamic> json) {
    return AiTopic(
      date: json['date'] is String
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      topic: json['topic'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'topic': topic,
      };
}

class ConversationPatterns {
  final String avgResponseLength; // "short" | "medium" | "long"
  final List<String> commonComplaints;
  final String moodTrend; // "stable" | "improving" | "declining"
  final List<String> cognitiveFlags;

  const ConversationPatterns({
    this.avgResponseLength = 'medium',
    this.commonComplaints = const [],
    this.moodTrend = 'stable',
    this.cognitiveFlags = const [],
  });

  factory ConversationPatterns.fromJson(Map<String, dynamic> json) {
    return ConversationPatterns(
      avgResponseLength:
          json['avgResponseLength'] as String? ?? 'medium',
      commonComplaints: (json['commonComplaints'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      moodTrend: json['moodTrend'] as String? ?? 'stable',
      cognitiveFlags: (json['cognitiveFlags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'avgResponseLength': avgResponseLength,
        'commonComplaints': commonComplaints,
        'moodTrend': moodTrend,
        'cognitiveFlags': cognitiveFlags,
      };

  ConversationPatterns copyWith({
    String? avgResponseLength,
    List<String>? commonComplaints,
    String? moodTrend,
    List<String>? cognitiveFlags,
  }) {
    return ConversationPatterns(
      avgResponseLength: avgResponseLength ?? this.avgResponseLength,
      commonComplaints: commonComplaints ?? this.commonComplaints,
      moodTrend: moodTrend ?? this.moodTrend,
      cognitiveFlags: cognitiveFlags ?? this.cognitiveFlags,
    );
  }
}

class AiMemory {
  final List<String> personalFacts;
  final List<AiTopic> recentTopics;
  final ConversationPatterns conversationPatterns;
  final DateTime lastUpdated;

  const AiMemory({
    this.personalFacts = const [],
    this.recentTopics = const [],
    this.conversationPatterns = const ConversationPatterns(),
    required this.lastUpdated,
  });

  factory AiMemory.fromJson(Map<String, dynamic> json) {
    return AiMemory(
      personalFacts: (json['personalFacts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recentTopics: (json['recentTopics'] as List<dynamic>?)
              ?.map((e) => AiTopic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      conversationPatterns: json['conversationPatterns'] != null
          ? ConversationPatterns.fromJson(
              json['conversationPatterns'] as Map<String, dynamic>)
          : const ConversationPatterns(),
      lastUpdated: json['lastUpdated'] is String
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'personalFacts': personalFacts,
        'recentTopics': recentTopics.map((t) => t.toJson()).toList(),
        'conversationPatterns': conversationPatterns.toJson(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  AiMemory copyWith({
    List<String>? personalFacts,
    List<AiTopic>? recentTopics,
    ConversationPatterns? conversationPatterns,
    DateTime? lastUpdated,
  }) {
    return AiMemory(
      personalFacts: personalFacts ?? this.personalFacts,
      recentTopics: recentTopics ?? this.recentTopics,
      conversationPatterns:
          conversationPatterns ?? this.conversationPatterns,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
