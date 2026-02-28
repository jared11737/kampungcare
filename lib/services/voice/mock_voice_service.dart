import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../config/constants.dart';
import 'voice_service_base.dart';

/// Voice service that wraps REAL speech_to_text and flutter_tts packages.
/// These work offline so they're suitable for development without Firebase.
/// Falls back gracefully if STT is unavailable on the device.
class MockVoiceService implements VoiceServiceBase {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _sttAvailable = false;
  String _currentLocale = '';

  final _partialResultController = StreamController<String>.broadcast();

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize STT
      _sttAvailable = await _stt.initialize(
        onStatus: (status) {
          _isListening = status == 'listening';
          print('[Voice] STT status: $status');
        },
        onError: (error) {
          print('[Voice] STT error: ${error.errorMsg}');
          _isListening = false;
        },
      );

      if (!_sttAvailable) {
        print('[Voice] STT not available on this device — listen() will return null');
      }

      // Initialize TTS with locale based on language setting
      _currentLocale = S.isEnglish ? 'en-US' : 'ms-MY';
      await _tts.setLanguage(_currentLocale);
      await _tts.setSpeechRate(AppConstants.voiceSpeechRate);
      await _tts.setPitch(AppConstants.voicePitch);
      await _tts.setVolume(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      _tts.setErrorHandler((msg) {
        print('[Voice] TTS error: $msg');
        _isSpeaking = false;
      });

      _isInitialized = true;
      print('[Voice] Initialized — STT available: $_sttAvailable');
      return true;
    } catch (e) {
      print('[Voice] Initialization failed: $e');
      return false;
    }
  }

  @override
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();

    // Stop any ongoing listening before speaking
    if (_isListening) {
      await stopListening();
    }

    // Only update locale if language setting has changed
    final locale = S.isEnglish ? 'en-US' : 'ms-MY';
    if (locale != _currentLocale) {
      _currentLocale = locale;
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(AppConstants.voiceSpeechRate);
    }
    _isSpeaking = true;
    await _tts.speak(text);
    print('[Voice] Speaking: ${text.length > 50 ? '${text.substring(0, 50)}...' : text}');
  }

  @override
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  @override
  Future<String?> listen({Duration? timeout}) async {
    if (!_isInitialized) await initialize();
    if (!_sttAvailable) {
      print('[Voice] STT not available, returning null');
      return null;
    }

    // Stop speaking before listening
    if (_isSpeaking) {
      await stopSpeaking();
    }

    final completer = Completer<String?>();
    Timer? timeoutTimer;

    // Set up timeout if provided
    if (timeout != null) {
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          _stt.stop();
          completer.complete(null);
        }
      });
    }

    try {
      _isListening = true;
      await _stt.listen(
        onResult: (result) {
          // Emit partial results
          if (!result.finalResult) {
            _partialResultController.add(result.recognizedWords);
          }

          // Complete with final result
          if (result.finalResult && !completer.isCompleted) {
            timeoutTimer?.cancel();
            final text = result.recognizedWords.isNotEmpty
                ? result.recognizedWords
                : null;
            completer.complete(text);
            print('[Voice] Heard: $text');
          }
        },
        localeId: S.isEnglish ? 'en-US' : 'ms-MY',
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      print('[Voice] Listen error: $e');
      if (!completer.isCompleted) {
        timeoutTimer?.cancel();
        completer.complete(null);
      }
    }

    return completer.future;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    await _stt.stop();
  }

  @override
  bool get isListening => _isListening;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Stream<String> get onPartialResult => _partialResultController.stream;

  @override
  Future<void> dispose() async {
    await stopSpeaking();
    await stopListening();
    await _stt.cancel();
    _partialResultController.close();
    _isInitialized = false;
    print('[Voice] Disposed');
  }
}
