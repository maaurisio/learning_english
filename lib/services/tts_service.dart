import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  final FlutterTts _flutterTts = FlutterTts();

  factory TtsService() => _instance;

  TtsService._internal();

  Future<void> initialize({
    String language = 'en-US',
    double speed = 0.5,
    double pitch = 1.0,
  }) async {
    try {
      await _flutterTts.setLanguage(language);
      await _flutterTts.setSpeechRate(speed);
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      throw Exception('Failed to initialize TTS: $e');
    }
  }

  Future<void> speak(String text) async {
    try {
      if (text.trim().isEmpty) return;
      await _flutterTts.speak(text);
    } catch (e) {
      throw Exception('Failed to speak text: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      throw Exception('Failed to stop TTS: $e');
    }
  }

  Future<void> setSpeed(double speed) async {
    try {
      await _flutterTts.setSpeechRate(speed);
    } catch (e) {
      throw Exception('Failed to set speech rate: $e');
    }
  }

  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      throw Exception('Failed to set pitch: $e');
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
    } catch (e) {
      throw Exception('Failed to set language: $e');
    }
  }

  Future<bool> isSpeaking() async {
    try {
      return await _flutterTts.isSpeaking;
    } catch (e) {
      return false;
    }
  }

  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
      await _flutterTts.setLanguage('');
    } catch (e) {
      // Ignore errors during disposal
    }
  }
}
