import '../models/user_profile.dart';
import '../models/health_log.dart';
import '../models/medication.dart';
import '../models/medication_log.dart';
import '../models/conversation.dart';
import '../models/alert.dart';
import '../models/care_network.dart';
import '../models/ai_memory.dart';
import '../models/caregiver_view.dart';

class MockData {
  // ======== USERS ========

  static UserProfile get elderlyUser => UserProfile(
        uid: 'siti_001',
        name: 'Siti binti Ahmad',
        age: 74,
        phone: '+60121234567',
        language: 'ms',
        address: '123 Jalan Makmur, Kuantan, Pahang',
        bloodType: 'B+',
        allergies: ['Penicillin'],
        preferredHospital: 'Hospital Tengku Ampuan Afzan',
        emergencyNote: 'Diabetes Type 2, Hypertension',
        role: UserRole.elderly,
        conditions: [
          Condition(name: 'Diabetes Type 2', since: '2015', severity: 'managed'),
          Condition(name: 'Hypertension', since: '2018', severity: 'managed'),
          Condition(name: 'Knee Arthritis', since: '2020', severity: 'moderate'),
        ],
        createdAt: DateTime(2026, 1, 15),
      );

  static UserProfile get caregiver => UserProfile(
        uid: 'aisyah_001',
        name: 'Aisyah binti Ismail',
        age: 42,
        phone: '+60191234567',
        language: 'ms',
        address: '45 Jalan Ampang, Kuala Lumpur',
        bloodType: 'O+',
        allergies: [],
        preferredHospital: '',
        emergencyNote: '',
        role: UserRole.caregiver,
        conditions: [],
        createdAt: DateTime(2026, 1, 15),
      );

  static UserProfile get buddy => UserProfile(
        uid: 'zainab_001',
        name: 'Zainab binti Hassan',
        age: 55,
        phone: '+60171234567',
        language: 'ms',
        address: '125 Jalan Makmur, Kuantan, Pahang',
        bloodType: 'A+',
        allergies: [],
        preferredHospital: '',
        emergencyNote: '',
        role: UserRole.buddy,
        conditions: [],
        createdAt: DateTime(2026, 1, 16),
      );

  // ======== MEDICATIONS ========

  static List<Medication> get medications => [
        Medication(
          id: 'med_001',
          name: 'Metformin 500mg',
          dosage: '1 tablet',
          times: ['07:00', '19:00'],
          pillDescription: 'Tablet putih bulat',
          instructions: 'Ambil selepas makan',
          prescribedBy: 'Dr. Ahmad',
          interactions: ['Elakkan alkohol'],
        ),
        Medication(
          id: 'med_002',
          name: 'Amlodipine 5mg',
          dosage: '1 tablet',
          times: ['07:00'],
          pillDescription: 'Tablet putih bujur kecil',
          instructions: 'Ambil pada waktu pagi',
          prescribedBy: 'Dr. Ahmad',
          interactions: [],
        ),
        Medication(
          id: 'med_003',
          name: 'Glucosamine 500mg',
          dosage: '2 tablet',
          times: ['07:00', '19:00'],
          pillDescription: 'Kapsul kuning',
          instructions: 'Untuk sakit lutut',
          prescribedBy: 'Dr. Lim',
          interactions: [],
        ),
      ];

  // ======== HEALTH LOGS (21 days, last 3 declining) ========

  static List<HealthLog> get healthLogs => _generateHealthLogs();

  static List<HealthLog> _generateHealthLogs() {
    final logs = <HealthLog>[];
    for (int i = 20; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final isRecent = i <= 2;
      final dayVariation = i % 3;

      logs.add(HealthLog(
        id: 'log_${20 - i}',
        type: 'check_in',
        timestamp: DateTime(date.year, date.month, date.day, 6, 30 + (i % 15)),
        mood: isRecent ? (2 + (dayVariation == 0 ? 1 : 0)) : (3 + (dayVariation < 2 ? 1 : 0)),
        sleepQuality: isRecent ? 2 : (3 + (dayVariation < 2 ? 1 : 0)),
        painLevel: {
          'knee': isRecent ? (4 + (dayVariation == 0 ? 1 : 0)).clamp(1, 5) : (2 + (dayVariation == 2 ? 1 : 0)),
        },
        notes: isRecent
            ? 'Sakit lutut bertambah, susah tidur'
            : dayVariation == 0
                ? 'Hari baik, mood ceria'
                : dayVariation == 1
                    ? 'Hari biasa, makan sedap'
                    : 'Lutut sakit sikit tapi boleh tahan',
        aiSummary: isRecent
            ? 'Sakit lutut bertambah teruk. Tidur terganggu. Perlu perhatian.'
            : 'Keadaan stabil. Tiada kebimbangan.',
        flags: isRecent ? ['pain_increasing', 'sleep_declining'] : [],
      ));
    }
    return logs;
  }

  // ======== MEDICATION LOGS (21 days, ~90% adherence) ========

  static List<MedicationLog> get medicationLogs => _generateMedicationLogs();

  static List<MedicationLog> _generateMedicationLogs() {
    final logs = <MedicationLog>[];
    int logIndex = 0;

    for (int i = 20; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final isHighPainDay = i <= 2 || i == 8 || i == 15;

      // Morning medications: Metformin, Amlodipine, Glucosamine
      for (final medId in ['med_001', 'med_002', 'med_003']) {
        final missed = isHighPainDay && medId == 'med_003' && i != 0;
        logs.add(MedicationLog(
          id: 'mlog_$logIndex',
          medicationId: medId,
          scheduledTime: '07:00',
          takenTime: missed ? null : DateTime(date.year, date.month, date.day, 7, 10 + (logIndex % 20)),
          status: missed ? MedicationStatus.missed : MedicationStatus.taken,
          photoVerified: !missed && logIndex % 3 == 0,
          geminiVerification: !missed && logIndex % 3 == 0
              ? {'correct': true, 'confidence': 0.92}
              : null,
        ));
        logIndex++;
      }

      // Evening medications: Metformin, Glucosamine
      for (final medId in ['med_001', 'med_003']) {
        final missed = isHighPainDay && medId == 'med_003';
        logs.add(MedicationLog(
          id: 'mlog_$logIndex',
          medicationId: medId,
          scheduledTime: '19:00',
          takenTime: missed ? null : DateTime(date.year, date.month, date.day, 19, 5 + (logIndex % 25)),
          status: missed ? MedicationStatus.missed : MedicationStatus.taken,
          photoVerified: false,
          geminiVerification: null,
        ));
        logIndex++;
      }
    }
    return logs;
  }

  // ======== CONVERSATIONS ========

  static List<Conversation> get conversations => [
        Conversation(
          id: 'conv_001',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          type: 'cerita',
          duration: 420,
          messages: [
            ChatMessage(role: 'assistant', content: 'Selamat petang, Mak Cik! Nak sembang apa hari ni?'),
            ChatMessage(role: 'user', content: 'Saya teringat hari perkahwinan saya dulu...'),
            ChatMessage(role: 'assistant', content: 'Wah, bestnya! Mak Cik kahwin tahun bila?'),
            ChatMessage(role: 'user', content: 'Tahun 1975. Arwah suami saya nampak kacak sangat hari tu. Dia pakai baju Melayu warna hijau.'),
            ChatMessage(role: 'assistant', content: 'Mesti Mak Cik pun cantik! Kenduri besar ke?'),
            ChatMessage(role: 'user', content: 'Mak saya masak untuk 200 orang! Nasi minyak, rendang, kuah kacang... Semua kampung datang.'),
            ChatMessage(role: 'assistant', content: 'Wah, sedapnya! Mesti meriah sangat. Mak Cik ada simpan gambar tak?'),
            ChatMessage(role: 'user', content: 'Ada, dalam album lama. Tapi gambar hitam putih je. Nak tunjuk Aisyah nanti.'),
          ],
          extractedData: {'mood': 4, 'emotionalState': 'nostalgic_happy'},
          aiNotes: 'Mak Cik Siti berkongsi cerita perkahwinan 1975. Mood positif, kenangan indah.',
        ),
        Conversation(
          id: 'conv_002',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          type: 'check_in',
          duration: 85,
          messages: [
            ChatMessage(role: 'assistant', content: 'Selamat pagi, Mak Cik Siti! Macam mana tidur malam tadi?'),
            ChatMessage(role: 'user', content: 'Tak berapa baik. Lutut sakit sangat semalam.'),
            ChatMessage(role: 'assistant', content: 'Kesian Mak Cik. Sakit tu dari semalam lagi ke, atau baru malam tadi?'),
            ChatMessage(role: 'user', content: 'Dah tiga hari macam ni. Makin teruk rasanya.'),
            ChatMessage(role: 'assistant', content: 'Saya faham. Mak Cik dah makan ubat Glucosamine tadi?'),
            ChatMessage(role: 'user', content: 'Dah, tapi macam tak berkesan sangat.'),
            ChatMessage(role: 'assistant', content: 'Takpe, Mak Cik. Saya beritahu Aisyah ya. Mungkin elok jumpa doktor. Jaga diri baik-baik!'),
          ],
          extractedData: {'mood': 2, 'sleep': 2, 'pain': {'knee': 4}},
          aiNotes: 'Sakit lutut bertambah teruk 3 hari berturut-turut. Tidur terganggu. Ubat Glucosamine kurang berkesan. Cadangan: maklumkan penjaga.',
        ),
        Conversation(
          id: 'conv_003',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          type: 'check_in',
          duration: 70,
          messages: [
            ChatMessage(role: 'assistant', content: 'Selamat pagi, Mak Cik! Macam mana hari ni? Lutut masih sakit?'),
            ChatMessage(role: 'user', content: 'Masih sakit. Semalam susah nak tidur.'),
            ChatMessage(role: 'assistant', content: 'Kesian. Mak Cik dah cuba letak tuala panas kat lutut?'),
            ChatMessage(role: 'user', content: 'Dah cuba, tapi kejap je lega. Lepas tu sakit balik.'),
            ChatMessage(role: 'assistant', content: 'Mak Cik, saya fikir elok jumpa doktor. Saya beritahu Aisyah ya supaya dia tolong buat appointment. Mak Cik rehat banyak-banyak hari ni.'),
          ],
          extractedData: {'mood': 2, 'sleep': 2, 'pain': {'knee': 5}},
          aiNotes: 'Sakit lutut masih teruk, hari ke-4. Tidur terganggu. Tuala panas tidak membantu. Perlu jumpa doktor.',
        ),
        Conversation(
          id: 'conv_004',
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          type: 'casual',
          duration: 180,
          messages: [
            ChatMessage(role: 'assistant', content: 'Hai Mak Cik! Petang ni buat apa?'),
            ChatMessage(role: 'user', content: 'Baru siap siram orkid. Orkid ungu tu dah kembang!'),
            ChatMessage(role: 'assistant', content: 'Wah bestnya! Mak Cik memang pandai jaga orkid. Yang ungu tu jenis apa?'),
            ChatMessage(role: 'user', content: 'Dendrobium. Arwah suami yang beli dulu. Dah 5 tahun saya jaga.'),
            ChatMessage(role: 'assistant', content: 'Cantiknya kenangan tu. Orkid hidup lama kalau dijaga dengan baik, macam kenangan yang indah.'),
          ],
          extractedData: {'mood': 4, 'emotionalState': 'content'},
          aiNotes: 'Mood baik. Berkebun orkid, kenangan positif tentang arwah suami.',
        ),
      ];

  // ======== AI MEMORY ========

  static AiMemory get aiMemory => AiMemory(
        personalFacts: [
          'Ada 3 anak: Aisyah (KL), Ahmad (Singapura), Fatimah (Kuantan)',
          'Arwah suami Encik Ismail meninggal 2019',
          'Suka berkebun, terutama orkid',
          'Makanan kegemaran laksa Pahang',
          'Dulu cikgu sekolah rendah',
          'Rumah warna hijau di hujung jalan',
          'Ada kucing nama Si Comel',
          'Suka dengar lagu P. Ramlee',
        ],
        recentTopics: [
          AiTopic(
            date: DateTime.now().subtract(const Duration(days: 3)),
            topic: 'Cerita tentang hari perkahwinan tahun 1975',
          ),
          AiTopic(
            date: DateTime.now().subtract(const Duration(days: 2)),
            topic: 'Sakit lutut bertambah, tidur terganggu',
          ),
          AiTopic(
            date: DateTime.now().subtract(const Duration(days: 1)),
            topic: 'Lutut masih sakit, ubat kurang berkesan',
          ),
          AiTopic(
            date: DateTime.now().subtract(const Duration(days: 5)),
            topic: 'Gembira orkid ungu dah kembang',
          ),
        ],
        conversationPatterns: ConversationPatterns(
          avgResponseLength: 'medium',
          commonComplaints: ['sakit lutut', 'sunyi', 'susah tidur'],
          moodTrend: 'declining_slightly',
          cognitiveFlags: [],
        ),
        lastUpdated: DateTime.now().subtract(const Duration(hours: 3)),
      );

  // ======== CARE NETWORK ========

  static CareNetwork get careNetwork => CareNetwork(
        caregivers: [
          CareContact(
            uid: 'aisyah_001',
            name: 'Aisyah',
            relation: 'anak perempuan',
            phone: '+60191234567',
          ),
        ],
        buddies: [
          CareContact(
            uid: 'zainab_001',
            name: 'Kak Zainab',
            relation: 'jiran',
            phone: '+60171234567',
            distance: '50m',
          ),
        ],
        escalationOrder: ['buddy', 'caregiver', 'emergency_services'],
      );

  // ======== CAREGIVER VIEW ========

  static CaregiverView get caregiverView => CaregiverView(
        currentStatus: 'green',
        lastCheckIn: DateTime.now().subtract(const Duration(hours: 3)),
        todayMedsTaken: 2,
        todayMedsScheduled: 3,
        weeklyMoodAvg: 3.5,
        activeConcerns: [],
        weeklySummary:
            'Mak Cik Siti sihat minggu ni secara keseluruhannya. Dia ambil ubat 19 daripada 21 dos. '
            'Mood dia baik dari Isnin sampai Khamis tapi dia nampak senyap sikit Jumaat dan Sabtu. '
            'Sakit lutut dia stabil. Dia cerita kisah manis tentang hari perkahwinan dia pada hari Rabu.',
      );

  // ======== ALERTS ========

  static List<Alert> get alerts => [
        Alert(
          id: 'alert_001',
          elderlyUid: 'siti_001',
          type: AlertType.missedCheckin,
          severity: AlertSeverity.yellow,
          message: 'Mak Cik Siti belum check in pagi tadi',
          status: AlertStatus.resolved,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          resolvedBy: 'zainab_001',
          resolvedAt: DateTime.now().subtract(const Duration(days: 5, hours: -1)),
        ),
        Alert(
          id: 'alert_002',
          elderlyUid: 'siti_001',
          type: AlertType.missedMedication,
          severity: AlertSeverity.yellow,
          message: 'Mak Cik Siti tak ambil ubat Glucosamine 3 kali minggu ni',
          status: AlertStatus.acknowledged,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

  // ======== WEEKLY SUMMARY (for caregiver) ========

  static Map<String, dynamic> get weeklySummaryData => {
        'summary_bm':
            'Mak Cik Siti sihat minggu ni secara keseluruhannya. Dia ambil ubat 19 daripada 21 dos. '
                'Mood dia baik dari Isnin sampai Khamis tapi dia nampak senyap sikit Jumaat dan Sabtu. '
                'Sakit lutut dia bertambah dalam 3 hari terakhir. '
                'Dia cerita kisah manis tentang hari perkahwinan dia pada hari Rabu.',
        'summary_en':
            'Mak Cik Siti had a generally good week. She took 19 of 21 medication doses. '
                'Her mood was positive Monday through Thursday but she seemed quieter on Friday and Saturday. '
                'Her knee pain has worsened over the last 3 days. '
                'She shared a lovely story about her wedding day on Wednesday.',
        'highlight': 'Dia sangat ceria pada hari Rabu dan berkongsi kisah indah tentang pertemuan dengan ayah anda.',
        'concern': 'Sakit lutut dia bertambah 3 hari berturut-turut dan tidur terganggu. Mungkin perlu jumpa doktor.',
        'suggested_action': 'Panggilan telefon atau lawatan hujung minggu ini akan menceriakan hatinya. Tanya dia tentang cerita perkahwinan.',
        'shared_story':
            'Pada hari Rabu, dia ceritakan kisah hari perkahwinannya pada tahun 1975 — '
                'betapa nervousnya ayah anda dan bagaimana ibunya memasak untuk 200 tetamu.',
      };
}
