import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class AppSettings {
  final double textScale;
  final String morningCheckInTime;
  final double voiceSpeed;
  final bool isEnglish;

  const AppSettings({
    this.textScale = 1.0,
    this.morningCheckInTime = '06:30',
    this.voiceSpeed = 0.6,
    this.isEnglish = false,
  });

  AppSettings copyWith({
    double? textScale,
    String? morningCheckInTime,
    double? voiceSpeed,
    bool? isEnglish,
  }) {
    return AppSettings(
      textScale: textScale ?? this.textScale,
      morningCheckInTime: morningCheckInTime ?? this.morningCheckInTime,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      isEnglish: isEnglish ?? this.isEnglish,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnglish = prefs.getBool('isEnglish') ?? false;
    state = AppSettings(
      textScale: prefs.getDouble('textScale') ?? 1.0,
      morningCheckInTime: prefs.getString('morningCheckInTime') ?? '06:30',
      voiceSpeed: prefs.getDouble('voiceSpeed') ?? 0.6,
      isEnglish: isEnglish,
    );
    S.isEnglish = isEnglish;  // sync static flag on startup
  }

  Future<void> setTextScale(double scale) async {
    state = state.copyWith(textScale: scale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScale', scale);
  }

  Future<void> setMorningCheckInTime(String time) async {
    state = state.copyWith(morningCheckInTime: time);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('morningCheckInTime', time);
  }

  Future<void> setVoiceSpeed(double speed) async {
    state = state.copyWith(voiceSpeed: speed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('voiceSpeed', speed);
  }

  Future<void> setIsEnglish(bool value) async {
    S.isEnglish = value;
    state = state.copyWith(isEnglish: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEnglish', value);
  }
}
