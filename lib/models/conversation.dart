class ChatMessage {
  final String role; // "assistant" | "user"
  final String content;

  const ChatMessage({
    required this.role,
    required this.content,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class Conversation {
  final String id;
  final DateTime timestamp;
  final String type; // "check_in" | "cerita" | "casual" | "emergency"
  final int duration; // seconds
  final List<ChatMessage> messages;
  final Map<String, dynamic>? extractedData;
  final Map<String, dynamic>? cognitiveAssessment;
  final String aiNotes;

  const Conversation({
    required this.id,
    required this.timestamp,
    required this.type,
    this.duration = 0,
    this.messages = const [],
    this.extractedData,
    this.cognitiveAssessment,
    this.aiNotes = '',
  });

  factory Conversation.fromJson(Map<String, dynamic> json, {String? id}) {
    return Conversation(
      id: id ?? json['id'] as String? ?? '',
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      type: json['type'] as String? ?? 'casual',
      duration: json['duration'] as int? ?? 0,
      messages: (json['messages'] as List<dynamic>?)
              ?.map(
                  (e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      extractedData: json['extractedData'] as Map<String, dynamic>?,
      cognitiveAssessment:
          json['cognitiveAssessment'] as Map<String, dynamic>?,
      aiNotes: json['aiNotes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type,
        'duration': duration,
        'messages': messages.map((m) => m.toJson()).toList(),
        'extractedData': extractedData,
        'cognitiveAssessment': cognitiveAssessment,
        'aiNotes': aiNotes,
      };

  Conversation copyWith({
    String? id,
    DateTime? timestamp,
    String? type,
    int? duration,
    List<ChatMessage>? messages,
    Map<String, dynamic>? extractedData,
    Map<String, dynamic>? cognitiveAssessment,
    String? aiNotes,
  }) {
    return Conversation(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      messages: messages ?? this.messages,
      extractedData: extractedData ?? this.extractedData,
      cognitiveAssessment: cognitiveAssessment ?? this.cognitiveAssessment,
      aiNotes: aiNotes ?? this.aiNotes,
    );
  }
}
