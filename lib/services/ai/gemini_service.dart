import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_service_base.dart';

class GeminiService implements AiServiceBase {
  static const _key = String.fromEnvironment('GEMINI_API_KEY');

  late final GenerativeModel _chat;
  late final GenerativeModel _extract;
  late final GenerativeModel _vision;

  GeminiService() {
    _chat = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _key,
      generationConfig: GenerationConfig(maxOutputTokens: 500, temperature: 0.7),
    );
    _extract = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _key,
      generationConfig: GenerationConfig(maxOutputTokens: 300, temperature: 0.3),
    );
    _vision = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _key,
      generationConfig: GenerationConfig(maxOutputTokens: 200, temperature: 0.3),
    );
  }

  @override
  Future<String> sendMessage(String type, String msg,
      {List<Map<String, String>>? history}) async {
    try {
      final chat = _chat.startChat(history: [
        Content.text(_systemPrompt(type)),
        ...(history ?? []).map((m) => m['role'] == 'user'
            ? Content.text(m['content']!)
            : Content.model([TextPart(m['content']!)])),
      ]);
      return (await chat.sendMessage(Content.text(msg))).text ??
          'Maaf, Sayang tak faham. Boleh ulang?';
    } catch (e) {
      print('[Gemini] sendMessage: $e');
      return 'Maaf, ada masalah teknikal.';
    }
  }

  @override
  Future<Map<String, dynamic>> extractHealthData(String transcript) async {
    try {
      const prompt = 'Extract health data as JSON only: '
          '{"mood":1-5,"sleepQuality":1-5,"painLevels":{"knee":0-10},'
          '"flags":[],"shouldAlertCaregiver":false,"aiSummary":"sentence"}';
      final r = await _extract
          .generateContent([Content.text('$prompt\nTranscript:\n$transcript')]);
      return _json(r.text ?? '{}');
    } catch (_) {
      return {
        'mood': 3,
        'sleepQuality': 3,
        'painLevels': {},
        'flags': [],
        'shouldAlertCaregiver': false,
      };
    }
  }

  @override
  Future<Map<String, dynamic>> verifyMedication(
      dynamic photoBytes, List<dynamic> meds) async {
    try {
      final desc = meds
          .map((m) => '${m['name']}: ${m['pillDescription'] ?? ''}')
          .join('\n');
      final prompt = 'Identify pill vs expected:\n$desc\nJSON: '
          '{"identified":"","correct":true,"confidence":0.9,"notes":""}';
      final r = await _vision.generateContent([
        Content.multi(
            [TextPart(prompt), DataPart('image/jpeg', photoBytes is Uint8List ? photoBytes : Uint8List.fromList(photoBytes as List<int>))]),
      ]);
      return _json(r.text ?? '{}');
    } catch (_) {
      return {'identified': 'unknown', 'correct': false, 'confidence': 0.0};
    }
  }

  @override
  Future<Map<String, dynamic>> analyzePatterns(List<dynamic> logs) async {
    try {
      const prompt = 'Analyze health logs. JSON: '
          '{"overallStatus":"good|mild_concern|concerning",'
          '"shouldAlertCaregiver":false,"trends":{},"concerns":[],"recommendations":[]}';
      final r = await _extract
          .generateContent([Content.text('$prompt\nLogs:\n${jsonEncode(logs)}')]);
      return _json(r.text ?? '{}');
    } catch (_) {
      return {'overallStatus': 'good', 'shouldAlertCaregiver': false};
    }
  }

  @override
  Future<Map<String, dynamic>> generateWeeklySummary(String uid) async {
    try {
      const prompt = 'Weekly caregiver summary. JSON: '
          '{"summary_bm":"","highlight":"","concern":"","suggested_action":""}';
      final r = await _extract.generateContent([Content.text(prompt)]);
      return _json(r.text ?? '{}');
    } catch (_) {
      return {
        'summary_bm': '',
        'highlight': '',
        'concern': '',
        'suggested_action': '',
      };
    }
  }

  @override
  String getInitialGreeting(String type) => switch (type) {
        'check_in' => 'Selamat pagi! Macam mana keadaan Mak Cik hari ini?',
        'cerita' => 'Apa cerita hari ini? Sayang nak dengar.',
        _ => 'Assalamualaikum! Apa khabar?',
      };

  String _systemPrompt(String type) {
    const base = 'You are Sayang, a warm AI companion for elderly Malaysians. '
        'Speak ONLY Bahasa Melayu. Be patient and caring. '
        'Address as Mak Cik/Pak Cik. Max 3 sentences per reply.';
    return switch (type) {
      'check_in' => '$base Ask about health, sleep, mood.',
      'cerita' => '$base Encourage sharing memories.',
      _ => base,
    };
  }

  Map<String, dynamic> _json(String text) {
    try {
      final m = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      return jsonDecode(m?.group(0) ?? '{}') as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
