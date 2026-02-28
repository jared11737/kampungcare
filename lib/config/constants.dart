class AppConstants {
  // App info
  static const String appName = 'KampungCare';
  static const String aiCompanionName = 'Sayang';
  static const String tagline = 'Membina semula kampung untuk era digital';
  static const String packageName = 'com.kampungcare.app';

  // UI sizes
  static const double minTouchTarget = 64.0;
  static const double sosTouchTarget = 120.0;
  static const double minTextSize = 20.0;
  static const double buttonTextSize = 24.0;
  static const double headerTextSize = 28.0;
  static const double avatarSize = 120.0;
  static const double buttonSpacing = 16.0;
  static const double screenPadding = 20.0;

  // Timing
  static const int sosCountdownSeconds = 10;
  static const int silencePromptSeconds = 5;
  static const int silenceAutoEndSeconds = 30;
  static const int maxConversationExchanges = 6;
  static const int medicationSnoozeMinutes = 10;

  // Voice
  static const double voiceSpeechRate = 0.6;
  static const double voicePitch = 1.0;

  // Animation
  static const Duration transitionDuration = Duration(milliseconds: 300);
  static const Duration fadeInDuration = Duration(milliseconds: 400);

  // Default user settings
  static const String defaultMorningCheckIn = '06:30';
  static const String defaultEveningCheckIn = '20:00';
  static const int defaultGracePeriodMinutes = 30;
  static const double defaultTextScale = 1.3;
}

class BmStrings {
  // Greetings
  static const String selamatPagi = 'Selamat Pagi';
  static const String selamatTengahari = 'Selamat Tengah Hari';
  static const String selamatPetang = 'Selamat Petang';
  static const String selamatMalam = 'Selamat Malam';

  // Home screen
  static const String sembang = 'Sembang';
  static const String ubat = 'Ubat';
  static const String kesihatan = 'Kesihatan';
  static const String keluarga = 'Keluarga';
  static const String kecemasan = 'KECEMASAN';
  static const String tetapan = 'Tetapan';

  // Status
  static const String semuaBaik = 'Semua Baik Hari Ini';
  static const String perluPerhatian = 'Perlu Perhatian';
  static const String kecemasan2 = 'Kecemasan Aktif';

  // Medication
  static const String masaUbat = 'Masa Ubat';
  static const String sudahAmbil = 'Sudah Ambil';
  static const String ambilGambar = 'Ambil Gambar';
  static const String ingatkanLagi = 'Ingatkan lagi 10 minit';
  static const String ubatPagi = 'Ubat Pagi';
  static const String ubatMalam = 'Ubat Malam';

  // Voice chat
  static const String tamat = 'Tamat';
  static const String mendengar = 'Mendengar...';
  static const String berfikir = 'Berfikir...';
  static const String bercakap = 'Bercakap...';
  static const String checkInSelesai = 'Check-in selesai';

  // SOS
  static const String menghantar = 'Menghantar kecemasan dalam';
  static const String batalkan = 'Batalkan';
  static const String sayaOk = 'Saya OK';
  static const String panggil999 = 'Panggil 999';
  static const String dimaklumkan = 'dimaklumkan';
  static const String menghantar2 = 'menghantar...';
  static const String lokasiDihantar = 'Lokasi anda dihantar';

  // Auth
  static const String masuk = 'Masuk';
  static const String hantarOtp = 'Hantar OTP';
  static const String masukSebagai = 'Masuk sebagai';
  static const String nomorTelefon = 'Nombor Telefon';

  // Caregiver
  static const String dashboard = 'Dashboard Penjaga';
  static const String ringkasanMingguan = 'Ringkasan Mingguan';
  static const String trendMingguIni = 'Trend Minggu Ini';
  static const String ceritaDikongsi = 'Cerita Dikongsi';
  static const String panggilMakCik = 'Panggil Mak Cik';

  // General
  static const String silaTunggu = 'Sila tunggu...';
  static const String cubaLagi = 'Cuba lagi';
  static const String batal = 'Batal';
  static const String simpan = 'Simpan';
  static const String ok = 'OK';

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return selamatPagi;
    if (hour < 15) return selamatTengahari;
    if (hour < 19) return selamatPetang;
    return selamatMalam;
  }

  static String malayDate(DateTime date) {
    const days = ['Isnin', 'Selasa', 'Rabu', 'Khamis', 'Jumaat', 'Sabtu', 'Ahad'];
    const months = [
      'Januari', 'Februari', 'Mac', 'April', 'Mei', 'Jun',
      'Julai', 'Ogos', 'September', 'Oktober', 'November', 'Disember'
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }
}

/// Static string accessor — reads S.isEnglish and returns the right locale string.
/// Set S.isEnglish = true/false from SettingsNotifier.setIsEnglish().
class S {
  S._();

  static bool isEnglish = false;

  // ── Navigation ──
  static String get sembang => isEnglish ? 'Chat' : BmStrings.sembang;
  static String get ubat => isEnglish ? 'Medicine' : BmStrings.ubat;
  static String get kesihatan => isEnglish ? 'Health' : BmStrings.kesihatan;
  static String get keluarga => isEnglish ? 'Family' : BmStrings.keluarga;
  static String get kecemasan => isEnglish ? 'EMERGENCY' : BmStrings.kecemasan;
  static String get tetapan => isEnglish ? 'Settings' : BmStrings.tetapan;

  // ── Status ──
  static String get semuaBaik => isEnglish ? 'All Good Today' : BmStrings.semuaBaik;
  static String get perluPerhatian => isEnglish ? 'Needs Attention' : BmStrings.perluPerhatian;

  // ── Voice chat ──
  static String get tamat => isEnglish ? 'End' : BmStrings.tamat;
  static String get mendengar => isEnglish ? 'Listening...' : BmStrings.mendengar;
  static String get berfikir => isEnglish ? 'Thinking...' : BmStrings.berfikir;
  static String get bercakap => isEnglish ? 'Speaking...' : BmStrings.bercakap;
  static String get checkInSelesai => isEnglish ? 'Check-in complete' : BmStrings.checkInSelesai;
  static String get silaTunggu => isEnglish ? 'Please wait...' : BmStrings.silaTunggu;

  // ── Medication ──
  static String get sudahAmbil => isEnglish ? 'Taken' : BmStrings.sudahAmbil;
  static String get ambilGambar => isEnglish ? 'Take Photo' : BmStrings.ambilGambar;
  static String get ingatkanLagi => isEnglish ? 'Remind in 10 min' : BmStrings.ingatkanLagi;
  static String get ubatPagi => isEnglish ? 'Morning' : BmStrings.ubatPagi;
  static String get ubatMalam => isEnglish ? 'Evening' : BmStrings.ubatMalam;
  static String get masaUbat => isEnglish ? 'Medicine Time' : BmStrings.masaUbat;

  // ── Auth ──
  static String get masuk => isEnglish ? 'Sign In' : BmStrings.masuk;
  static String get hantarOtp => isEnglish ? 'Send OTP' : BmStrings.hantarOtp;
  static String get nomorTelefon => isEnglish ? 'Phone Number' : BmStrings.nomorTelefon;

  // ── Caregiver ──
  static String get dashboard => isEnglish ? 'Caregiver Dashboard' : BmStrings.dashboard;
  static String get panggilMakCik => isEnglish ? 'Call Aunty' : BmStrings.panggilMakCik;

  // ── SOS ──
  static String get menghantar => isEnglish ? 'Sending emergency in' : BmStrings.menghantar;
  static String get batalkan => isEnglish ? 'Cancel' : BmStrings.batalkan;
  static String get sayaOk => isEnglish ? "I'm OK" : BmStrings.sayaOk;
  static String get panggil999 => isEnglish ? 'Call 999' : BmStrings.panggil999;
  static String get lokasiDihantar => isEnglish ? 'Your location has been sent' : BmStrings.lokasiDihantar;

  // ── General ──
  static String get batal => isEnglish ? 'Cancel' : BmStrings.batal;
  static String get simpan => isEnglish ? 'Save' : BmStrings.simpan;
  static String get ok => 'OK';
  static String get cubaLagi => isEnglish ? 'Try again' : BmStrings.cubaLagi;

  // ── Dynamic greeting ──
  static String greeting() {
    if (isEnglish) {
      final hour = DateTime.now().hour;
      if (hour < 12) return 'Good Morning';
      if (hour < 15) return 'Good Afternoon';
      if (hour < 19) return 'Good Evening';
      return 'Good Night';
    }
    return BmStrings.greeting();
  }

  static String date(DateTime d) {
    if (isEnglish) {
      const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
      const months = ['January','February','March','April','May','June',
        'July','August','September','October','November','December'];
      return '${days[d.weekday-1]}, ${d.day} ${months[d.month-1]} ${d.year}';
    }
    return BmStrings.malayDate(d);
  }

  // ── Health chart labels ──
  static List<String> get moodLabels => isEnglish
      ? ['Sad', 'Poor', 'Okay', 'Good', 'Happy']
      : ['Sedih', 'Kurang', 'Biasa', 'Baik', 'Gembira'];
  static List<String> get sleepLabels => isEnglish
      ? ['Bad', 'Poor', 'Moderate', 'Good', 'Great']
      : ['Teruk', 'Kurang', 'Sederhana', 'Baik', 'Nyenyak'];
  static List<String> get painLabels => isEnglish
      ? ['None', 'Mild', 'Moderate', 'Severe', 'Very Severe']
      : ['Tiada', 'Ringan', 'Sederhana', 'Teruk', 'Sangat Teruk'];
  static List<String> get dayLabels => isEnglish
      ? ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
      : ['Is', 'Se', 'Ra', 'Kh', 'Ju', 'Sa', 'Ah'];
}
