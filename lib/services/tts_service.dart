import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  late FlutterTts _flutterTts;
  bool _isPlaying = false;
  VoidCallback? _listener;

  bool get isPlaying => _isPlaying;

  void addListener(VoidCallback listener) {
    _listener = listener;
  }

  void removeListener() {
    _listener = null;
  }

  void _notifyListeners() {
    if (_listener != null) {
      _listener!();
    }
  }

  Future<void> init() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _isPlaying = true;
      _notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      _notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
      _notifyListeners();
    });
  }

  Future<void> speak(String text) async {
    await init();
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
    _notifyListeners();
  }
}
