import '../../config/constants.dart';
import '../../data/mock_data.dart';
import '../../models/health_extraction.dart';
import 'ai_service_base.dart';

/// A single exchange in a scripted conversation.
class ConversationExchange {
  final String aiMessage;
  final List<String> expectedKeywords;
  final Map<String, bool> healthExtraction;
  final bool isClosing;

  const ConversationExchange({
    required this.aiMessage,
    this.expectedKeywords = const [],
    this.healthExtraction = const {},
    this.isClosing = false,
  });
}

/// Mock Gemini service with DEEP scripted conversations for demo.
/// Uses a stateful conversation engine with keyword matching and
/// linear fallback for demo reliability.
class MockGeminiService implements AiServiceBase {
  // Track conversation turn index per type
  final Map<String, int> _turnIndex = {};

  // Flag to force wrong-pill result for demo
  bool forceWrongPill = false;

  // ======== MORNING CHECK-IN SCRIPT (6 exchanges) ========
  static const List<ConversationExchange> _checkInScript = [
    ConversationExchange(
      aiMessage:
          'Selamat pagi, Mak Cik Siti! Macam mana tidur malam tadi? '
          'Semalam Mak Cik kata lutut sakit, masih lagi ke?',
      expectedKeywords: ['tidur', 'sakit', 'lutut', 'baik', 'tak baik', 'ok', 'boleh'],
      healthExtraction: {'sleep': true, 'pain': true},
    ),
    ConversationExchange(
      aiMessage:
          'Alamak, dah tiga hari berturut-turut ni lutut sakit makin teruk. '
          'Mak Cik rasa sakit tu dari 1 sampai 5, berapa agaknya hari ni?',
      expectedKeywords: ['1', '2', '3', '4', '5', 'teruk', 'sikit', 'banyak', 'sederhana'],
      healthExtraction: {'painLevel': true},
    ),
    ConversationExchange(
      aiMessage:
          'Saya faham, Mak Cik. Kesian dia. '
          'Pagi ni dah makan ke belum? Kena makan dulu sebelum ubat tau.',
      expectedKeywords: ['makan', 'belum', 'dah', 'roti', 'nasi', 'tak lapa', 'sikit'],
      healthExtraction: {'appetite': true},
    ),
    ConversationExchange(
      aiMessage:
          'Bagus lah tu. Mak Cik, saya nak beritahu Aisyah pasal lutut ni ya. '
          'Dah tiga hari makin sakit, elok jumpa doktor. '
          'Aisyah boleh tolong buatkan appointment.',
      expectedKeywords: ['ok', 'boleh', 'ya', 'taknak', 'tak perlu', 'jangan'],
      healthExtraction: {'caregiverAlert': true},
    ),
    ConversationExchange(
      aiMessage:
          'InsyaAllah, Mak Cik. Nanti waktu ubat pagi saya ingatkan ya. '
          'Jangan lupa makan ubat Glucosamine untuk lutut tu. '
          'Ada apa-apa, Mak Cik tekan butang merah tu ya.',
      expectedKeywords: ['ok', 'terima kasih', 'baik', 'boleh'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage:
          'Jaga diri baik-baik hari ni, Mak Cik Siti. Sayang Mak Cik!',
      expectedKeywords: [],
      healthExtraction: {},
      isClosing: true,
    ),
  ];

  // ======== CERITA MODE SCRIPT (8 exchanges) ========
  static const List<ConversationExchange> _ceritaScript = [
    ConversationExchange(
      aiMessage:
          'Hai Mak Cik Siti! Semalam Mak Cik ada sebut pasal hari perkahwinan. '
          'Nak cerita lagi? Saya suka dengar cerita Mak Cik.',
      expectedKeywords: ['nak', 'boleh', 'ya', 'cerita', 'kahwin', 'ok'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage:
          'Wah, bestnya! Tahun berapa tu, Mak Cik? '
          'Mesti masa tu kampung lagi cantik, rumah kayu semua.',
      expectedKeywords: ['1975', '1970', '1980', 'lama', 'dulu', 'tahun'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage:
          'Subhanallah, tahun 1975! Arwah Encik Ismail nervous ke masa tu? '
          'Saya bayangkan dia pakai baju Melayu putih.',
      expectedKeywords: ['nervous', 'senyum', 'handsome', 'kacak', 'takut', 'gembira'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage:
          'Kacaknya! Mesti Mak Cik pun cantik masa tu. '
          'Siapa yang masak untuk kenduri kahwin? Mak Mak Cik ke?',
      expectedKeywords: ['mak', 'masak', 'kenduri', 'rendang', 'ayam', 'sedap', 'ramai'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage:
          'Rendang tok! Mesti wangi satu kampung. '
          'Berapa orang tetamu datang? Mesti ramai kan zaman dulu.',
      expectedKeywords: ['ramai', 'ratus', '200', '300', 'kampung', 'semua'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage:
          'Bestnya! 200 orang, gotong-royong masak. '
          'Mak Cik masih ingat bau masakan apa yang paling wangi masa tu?',
      expectedKeywords: ['rendang', 'lemak', 'kuih', 'nasi', 'bau', 'sedap', 'wangi'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage:
          'Mmmm, saya pun boleh bayangkan baunya! '
          'Apa kenangan paling manis yang Mak Cik ingat dari hari tu?',
      expectedKeywords: ['senyum', 'tangan', 'pelamin', 'gembira', 'bahagia', 'menangis'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage:
          'Kisah ni cantik sangat, Mak Cik. Terima kasih kerana kongsi. '
          'Saya simpan untuk Aisyah dan cucu-cucu baca nanti ya. '
          'Arwah Encik Ismail mesti tersenyum dari atas sana.',
      expectedKeywords: [],
      healthExtraction: {},
      isClosing: true,
    ),
  ];

  // ======== CONCERNING CHECK-IN SCRIPT (6 exchanges) ========
  static const List<ConversationExchange> _concerningScript = [
    ConversationExchange(
      aiMessage:
          'Selamat pagi, Mak Cik Siti! Macam mana pagi ni? '
          'Hari ni hari Khamis, dah masuk minggu ketiga bulan Februari.',
      expectedKeywords: ['pagi', 'ok', 'baik', 'hari', 'rabu', 'selasa', 'apa'],
      healthExtraction: {'timeOrientation': true},
    ),
    ConversationExchange(
      aiMessage:
          'Hmm, Mak Cik. Semalam kan Mak Cik cerita pasal cucu datang melawat hujung minggu ni. '
          'Mak Cik masih ingat?',
      expectedKeywords: ['ya', 'ingat', 'tak ingat', 'bila', 'cucu', 'betul ke'],
      healthExtraction: {'memory': true},
    ),
    ConversationExchange(
      aiMessage:
          'Takpe, Mak Cik. Mak Cik tidur lena ke malam tadi? '
          'Saya perasan Mak Cik nampak penat sikit hari ni.',
      expectedKeywords: ['tidur', 'tak lena', 'penat', 'terjaga', 'mimpi', 'ok'],
      healthExtraction: {'sleep': true, 'fatigue': true},
    ),
    ConversationExchange(
      aiMessage:
          'Saya faham. Takpe, rehat yang cukup penting. '
          'Mak Cik dah makan ke pagi ni? Jom makan dulu ya.',
      expectedKeywords: ['makan', 'belum', 'dah', 'tak lapa'],
      healthExtraction: {'appetite': true},
    ),
    ConversationExchange(
      aiMessage:
          'Mak Cik, apa kata kita telefon Aisyah kejap? '
          'Dia mesti rindu nak dengar suara Mak Cik. '
          'Boleh tanya dia pasal rancangan hujung minggu sekali.',
      expectedKeywords: ['ok', 'boleh', 'nak', 'taknak', 'nanti'],
      healthExtraction: {'caregiverAlert': true},
    ),
    ConversationExchange(
      aiMessage:
          'InsyaAllah, Mak Cik. Saya doakan Mak Cik sihat selalu. '
          'Rehat yang cukup hari ni, dan jangan lupa makan ubat ya. '
          'Sayang Mak Cik!',
      expectedKeywords: [],
      healthExtraction: {},
      isClosing: true,
    ),
  ];

  // ======== CASUAL CHAT SCRIPT (6 exchanges) ========
  static const List<ConversationExchange> _casualScript = [
    ConversationExchange(
      aiMessage:
          'Hai Mak Cik! Nak sembang apa hari ni? '
          'Semalam Mak Cik cerita pasal kuih raya arwah mak. Nak sambung?',
      expectedKeywords: ['nak', 'boleh', 'kuih', 'mak', 'cerita', 'lain'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage:
          'Wah, bestnya! Mak Cik pandai buat kuih koci ke? '
          'Saya dengar kuih koci Pahang memang sedap!',
      expectedKeywords: ['pandai', 'buat', 'koci', 'sedap', 'susah', 'senang'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage:
          'Mesti sedap tu, Mak Cik! Resipi turun-temurun lagi. '
          'Aisyah dengan cucu-cucu boleh belajar buat tak?',
      expectedKeywords: ['boleh', 'tak', 'aisyah', 'cucu', 'ajar', 'belajar'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage:
          'Idea bagus tu! Mak Cik boleh ajar cucu-cucu masa raya nanti. '
          'Mesti diorang suka. Apa lagi kuih yang Mak Cik pandai buat?',
      expectedKeywords: ['tart', 'bahulu', 'dodol', 'lemang', 'ketupat', 'banyak'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage:
          'Wah, banyaknya! Mak Cik ni chef betul. '
          'Saya nak simpan semua resipi ni untuk keluarga Mak Cik ya.',
      expectedKeywords: ['ok', 'boleh', 'terima kasih'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage:
          'Terima kasih sembang dengan saya, Mak Cik. '
          'Nanti kita borak lagi pasal masakan ya. Jaga diri!',
      expectedKeywords: [],
      healthExtraction: {},
      isClosing: true,
    ),
  ];

  // ======== ENGLISH CHECK-IN SCRIPT ========
  static const List<ConversationExchange> _checkInScriptEn = [
    ConversationExchange(
      aiMessage: 'Good morning, Aunty Siti! How did you sleep last night? '
          'You mentioned your knee was hurting — is it still bothering you?',
      expectedKeywords: ['sleep', 'pain', 'knee', 'good', 'bad', 'ok', 'fine'],
      healthExtraction: {'sleep': true, 'pain': true},
    ),
    ConversationExchange(
      aiMessage: 'Oh dear, that\'s three days in a row your knee has been getting worse. '
          'On a scale of 1 to 5, how bad is the pain today?',
      expectedKeywords: ['1', '2', '3', '4', '5', 'bad', 'little', 'a lot'],
      healthExtraction: {'painLevel': true},
    ),
    ConversationExchange(
      aiMessage: 'I understand, Aunty. I\'m sorry to hear that. '
          'Have you had breakfast yet? You should eat before taking your medicine.',
      expectedKeywords: ['eat', 'no', 'yes', 'bread', 'rice', 'not hungry'],
      healthExtraction: {'appetite': true},
    ),
    ConversationExchange(
      aiMessage: 'Good. Aunty, I\'d like to let Aisyah know about your knee. '
          'Three days of worsening pain — it would be good to see a doctor. '
          'Aisyah can help make an appointment.',
      expectedKeywords: ['ok', 'yes', 'no', 'sure', 'alright'],
      healthExtraction: {'caregiverAlert': true},
    ),
    ConversationExchange(
      aiMessage: 'Alright, Aunty. I\'ll remind you when it\'s medicine time. '
          'Don\'t forget your Glucosamine for the knee. '
          'If you need anything, press the red button.',
      expectedKeywords: ['ok', 'thank you', 'alright', 'sure'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage: 'Take good care of yourself today, Aunty Siti. Sayang loves you!',
      expectedKeywords: [],
      healthExtraction: {},
      isClosing: true,
    ),
  ];

  // ======== ENGLISH CERITA SCRIPT ========
  static const List<ConversationExchange> _ceritaScriptEn = [
    ConversationExchange(
      aiMessage: 'Hello, Aunty Siti! Yesterday you mentioned your wedding day. '
          'Would you like to share more? I love hearing your stories.',
      expectedKeywords: ['yes', 'sure', 'ok', 'story', 'wedding', 'tell'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage: 'How wonderful! What year was that, Aunty? '
          'I imagine the kampung looked so beautiful back then.',
      expectedKeywords: ['1975', '1970', '1980', 'long ago', 'old', 'year'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage: 'Subhanallah, 1975! Was the late Encik Ismail nervous that day? '
          'I imagine him looking so handsome.',
      expectedKeywords: ['nervous', 'smile', 'handsome', 'scared', 'happy'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage: 'So handsome! And I\'m sure you were beautiful too, Aunty. '
          'Who cooked for the wedding feast? Your mother?',
      expectedKeywords: ['mother', 'cook', 'feast', 'rendang', 'chicken'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage: 'Rendang tok! The whole kampung must have smelled wonderful. '
          'How many guests came? I bet there were so many.',
      expectedKeywords: ['many', 'hundred', '200', '300', 'village'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage: 'Amazing! 200 people, all coming together. '
          'What smell do you remember most fondly from that day?',
      expectedKeywords: ['rendang', 'rice', 'smell', 'delicious', 'kuih'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage: 'I can almost smell it too! '
          'What is the sweetest memory you have from that day?',
      expectedKeywords: ['smile', 'hand', 'happy', 'bliss', 'beautiful'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage: 'That is such a beautiful story, Aunty. Thank you for sharing. '
          'I\'ll keep it safe for Aisyah and the grandchildren to read one day. '
          'The late Encik Ismail must be smiling from above.',
      expectedKeywords: [],
      healthExtraction: {},
      isClosing: true,
    ),
  ];

  // ======== ENGLISH CONCERNING SCRIPT ========
  static const List<ConversationExchange> _concerningScriptEn = [
    ConversationExchange(
      aiMessage: 'Good morning, Aunty Siti! How are you feeling this morning? '
          'Today is Thursday, the third week of February.',
      expectedKeywords: ['morning', 'ok', 'good', 'day', 'what'],
      healthExtraction: {'timeOrientation': true},
    ),
    ConversationExchange(
      aiMessage: 'Hmm, Aunty. Yesterday you told me your grandchildren are visiting this weekend. '
          'Do you still remember that?',
      expectedKeywords: ['yes', 'remember', 'forgot', 'when', 'grandchildren'],
      healthExtraction: {'memory': true},
    ),
    ConversationExchange(
      aiMessage: 'That\'s okay, Aunty. Did you sleep well last night? '
          'You seem a little tired today.',
      expectedKeywords: ['sleep', 'no', 'tired', 'woke up', 'ok'],
      healthExtraction: {'sleep': true, 'fatigue': true},
    ),
    ConversationExchange(
      aiMessage: 'I understand. Rest is very important. '
          'Have you eaten breakfast yet? Let\'s make sure you eat something.',
      expectedKeywords: ['eat', 'no', 'yes', 'not hungry'],
      healthExtraction: {'appetite': true},
    ),
    ConversationExchange(
      aiMessage: 'Aunty, what if we call Aisyah for a moment? '
          'She would love to hear your voice. '
          'You can ask her about the weekend plans too.',
      expectedKeywords: ['ok', 'yes', 'want to', 'no', 'later'],
      healthExtraction: {'caregiverAlert': true},
    ),
    ConversationExchange(
      aiMessage: 'I pray you stay healthy, Aunty. '
          'Get enough rest today, and don\'t forget your medicine. '
          'Sayang loves you!',
      expectedKeywords: [],
      healthExtraction: {},
      isClosing: true,
    ),
  ];

  // ======== ENGLISH CASUAL SCRIPT ========
  static const List<ConversationExchange> _casualScriptEn = [
    ConversationExchange(
      aiMessage: 'Hi Aunty! What would you like to chat about today? '
          'Yesterday you mentioned your mother\'s Raya cookies. Want to continue?',
      expectedKeywords: ['yes', 'ok', 'cookies', 'mother', 'story', 'other'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage: 'Oh how lovely! Can you make kuih koci yourself, Aunty? '
          'I hear Pahang kuih koci is especially delicious!',
      expectedKeywords: ['can', 'make', 'koci', 'delicious', 'hard', 'easy'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage: 'That must be amazing — a recipe passed down through generations! '
          'Can Aisyah and the grandchildren learn to make it?',
      expectedKeywords: ['can', 'yes', 'aisyah', 'grandchildren', 'teach', 'learn'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage: 'What a wonderful idea! Aunty can teach the grandchildren during Raya. '
          'They\'ll love it. What other cookies are you good at making?',
      expectedKeywords: ['tart', 'bahulu', 'dodol', 'lemang', 'many'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage: 'Wow, so many! Aunty is truly a chef. '
          'I want to save all these recipes for your family.',
      expectedKeywords: ['ok', 'yes', 'thank you'],
      healthExtraction: {},
    ),
    ConversationExchange(
      aiMessage: 'Thank you for chatting with me today, Aunty. '
          'We\'ll talk more about cooking next time. Take care!',
      expectedKeywords: [],
      healthExtraction: {},
      isClosing: true,
    ),
  ];

  // ======== HEALTH EXTRACTION RESULTS ========

  static HealthExtraction get checkInExtraction => const HealthExtraction(
        mood: 3,
        sleepQuality: 2,
        painLevels: {'knee': 4},
        appetite: 'fair',
        emotionalState: 'mild_concern',
        cognitiveFlags: CognitiveFlags(),
        aiNotes:
            'Sakit lutut bertambah teruk 3 hari berturut-turut, menjejaskan tidur. '
            'Selera makan OK. Cadangan: maklumkan penjaga untuk temujanji doktor.',
        shouldAlertCaregiver: true,
        alertReason:
            'Worsening knee pain pattern over 3 consecutive days affecting sleep',
      );

  static HealthExtraction get ceritaExtraction => const HealthExtraction(
        mood: 4,
        cognitiveFlags: CognitiveFlags(
          repetition: false,
          wordFinding: 'normal',
          timeOrientation: 'normal',
          memoryGaps: 'normal',
          overallConcern: 'none',
        ),
        aiNotes:
            'Mood positif semasa bercerita. Ingatan jangka panjang baik — '
            'menceritakan kisah perkahwinan dengan detail. Tiada tanda kognitif membimbangkan.',
        shouldAlertCaregiver: false,
      );

  static HealthExtraction get concerningExtraction => const HealthExtraction(
        mood: 2,
        sleepQuality: 2,
        painLevels: {'knee': 3},
        appetite: 'fair',
        emotionalState: 'confused',
        cognitiveFlags: CognitiveFlags(
          repetition: true,
          wordFinding: 'mild_difficulty',
          timeOrientation: 'confused',
          memoryGaps: 'mild',
          overallConcern: 'mild',
        ),
        aiNotes:
            'Menunjukkan kekeliruan tentang hari dan mengulangi cerita semalam tanpa sedar. '
            'Kemungkinan tanda awal penurunan kognitif. Perlu pemantauan berterusan.',
        shouldAlertCaregiver: true,
        alertReason:
            'Mild cognitive concerns: time disorientation and story repetition',
      );

  static HealthExtraction get casualExtraction => const HealthExtraction(
        mood: 4,
        emotionalState: 'content',
        cognitiveFlags: CognitiveFlags(),
        aiNotes: 'Mood baik semasa berbual santai tentang masakan dan keluarga.',
        shouldAlertCaregiver: false,
      );

  /// Get the appropriate script for a conversation type.
  List<ConversationExchange> _getScript(String type) {
    if (S.isEnglish) {
      return switch (type) {
        'check_in' => _checkInScriptEn,
        'cerita' => _ceritaScriptEn,
        'concerning' => _concerningScriptEn,
        'casual' => _casualScriptEn,
        _ => _casualScriptEn,
      };
    }
    return switch (type) {
      'check_in' => _checkInScript,
      'cerita' => _ceritaScript,
      'concerning' => _concerningScript,
      'casual' => _casualScript,
      _ => _casualScript,
    };
  }

  /// Get the extraction result for a conversation type.
  HealthExtraction getExtractionForType(String type) {
    return switch (type) {
      'check_in' => checkInExtraction,
      'cerita' => ceritaExtraction,
      'concerning' => concerningExtraction,
      'casual' => casualExtraction,
      _ => checkInExtraction,
    };
  }

  @override
  Future<String> sendMessage(
    String conversationType,
    String userMessage, {
    List<Map<String, String>>? history,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final script = _getScript(conversationType);
    final key = conversationType;
    final turn = _turnIndex[key] ?? 0;

    _turnIndex[key] = turn + 1;

    if (turn < script.length) {
      return script[turn].aiMessage;
    }

    return S.isEnglish
        ? 'Thank you for chatting with me today, Aunty. Take care!'
        : 'Terima kasih kerana sembang dengan Sayang hari ni, Mak Cik. '
            'Jaga diri baik-baik ya!';
  }

  @override
  String getInitialGreeting(String conversationType) {
    final script = _getScript(conversationType);
    // Advance the turn counter so sendMessage() starts from exchange 1, not 0
    _turnIndex[conversationType] = 1;
    return script.isNotEmpty
        ? script[0].aiMessage
        : 'Hai Mak Cik! Macam mana hari ni?';
  }

  /// Get total exchange count for a conversation type.
  int getExchangeCount(String conversationType) {
    return _getScript(conversationType).length;
  }

  /// Check if the current exchange is the closing one.
  bool isClosingExchange(String conversationType) {
    final script = _getScript(conversationType);
    final turn = (_turnIndex[conversationType] ?? 0) - 1;
    if (turn >= 0 && turn < script.length) {
      return script[turn].isClosing;
    }
    return turn >= script.length;
  }

  @override
  Future<Map<String, dynamic>> extractHealthData(String transcript) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      'mood': 3,
      'sleepQuality': 2,
      'painLevel': {'knee': 4, 'general': 2},
      'notes': 'Sakit lutut bertambah, tidur terganggu 3 malam berturut-turut',
      'flags': ['pain_increasing', 'sleep_declining'],
      'shouldAlertCaregiver': true,
      'alertReason': 'Sakit lutut makin teruk 3 hari, perlu perhatian doktor',
      'cognitiveAssessment': {
        'repetition': false,
        'wordFinding': 'normal',
        'timeOrientation': 'normal',
        'overallConcern': 'none',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> verifyMedication(
    dynamic photoBytes,
    List<dynamic> meds,
  ) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (forceWrongPill) {
      forceWrongPill = false;
      return {
        'identified': true,
        'correct': false,
        'confidence': 0.88,
        'pillsDetected': 2,
        'matchedMedications': ['Amlodipine 5mg'],
        'wrongPill': 'Metformin 500mg',
        'notes':
            'Ubat yang dikesan ialah ubat MALAM (Amlodipine), bukan ubat pagi. '
            'Ubat pagi Metformin 500mg warna putih, bulat.',
        'correctDescription':
            'Ubat pagi yang betul: Metformin 500mg — pil putih, bulat, kecil.',
      };
    }

    return {
      'identified': true,
      'correct': true,
      'confidence': 0.92,
      'pillsDetected': 3,
      'matchedMedications': [
        'Metformin 500mg',
        'Amlodipine 5mg',
        'Glucosamine 500mg'
      ],
      'notes': 'Semua ubat pagi dikesan dengan betul.',
    };
  }

  @override
  Future<Map<String, dynamic>> analyzePatterns(List<dynamic> logs) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return {
      'overallStatus': 'mild_concern',
      'shouldAlertCaregiver': true,
      'trends': {
        'mood': 'declining_slightly',
        'sleep': 'declining',
        'pain': 'increasing',
        'medication_adherence': 'good',
      },
      'concerns': [
        'Sakit lutut bertambah 3 hari berturut-turut',
        'Kualiti tidur menurun',
        'Glucosamine mungkin kurang berkesan',
      ],
      'recommendations': [
        'Maklumkan penjaga tentang sakit lutut',
        'Cadangkan lawatan doktor',
        'Pantau tidur malam ini',
      ],
      'cognitiveStatus': 'normal',
    };
  }

  @override
  Future<Map<String, dynamic>> generateWeeklySummary(String userId) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return MockData.weeklySummaryData;
  }

  /// Reset conversation scripts for a specific type.
  void resetConversation(String conversationType) {
    _turnIndex[conversationType] = 0;
  }

  /// Reset all conversation turn counters.
  void resetAll() {
    _turnIndex.clear();
    forceWrongPill = false;
  }
}
