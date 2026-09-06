import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:learning_english/db/database_helper.dart';
import 'package:learning_english/models/word.dart';
import 'package:learning_english/models/user_progress.dart';
import 'package:learning_english/services/tts_service.dart';
import 'package:learning_english/widgets/glass_card.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  TestScreenState createState() => TestScreenState();
}

class TestScreenState extends State<TestScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TtsService _ttsService = TtsService();

  List<Word> _words = [];
  int _currentIndex = 0;
  int _wordsCorrect = 0;
  int _totalTests = 0;
  String _userAnswer = '';
  bool _isAnswered = false;
  bool _isCorrect = false;
  bool _isLoading = true;
  bool _hasAnyData = false;
  Timer? _timer;
  double _timeRemaining = 0;
  double _totalTime = 0;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  void reload() {
    _isLoading = true;
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    _cancelTimer();
    try {
      final allWords = await _dbHelper.getAllWords();
      final words = await _dbHelper.getUnlearnedWords();
      if (mounted) {
        setState(() {
          _words = words;
          _hasAnyData = allWords.isNotEmpty;
          _currentIndex = 0;
          _wordsCorrect = 0;
          _totalTests = 0;
          _isLoading = false;
          _isAnswered = false;
          _isCorrect = false;
          _userAnswer = '';
        });
        if (words.isNotEmpty) {
          _startNextQuestion();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startNextQuestion() {
    if (_currentIndex >= _words.length) {
      _finishTest();
      return;
    }

    _cancelTimer();

    final word = _words[_currentIndex];
    _totalTime = _calculateDuration(word.wordEn);
    _timeRemaining = _totalTime;
    _isAnswered = false;
    _isCorrect = false;
    _userAnswer = '';

    _ttsService.speak(word.wordEn);
    setState(() {});

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _timeRemaining -= 0.1;
        if (_timeRemaining <= 0) {
          _timeRemaining = 0;
          _timer?.cancel();
          _advanceQuestion();
        }
      });
    });
  }

  double _calculateDuration(String text) {
    final duration = ((text.length * 1.5).round() + 15).toDouble();
    return duration.clamp(15.0, 60.0).toDouble();
  }

  void _advanceQuestion() {
    _cancelTimer();
    if (!mounted) return;
    setState(() {
      _currentIndex++;
      if (_currentIndex < _words.length) {
        _startNextQuestion();
      } else {
        _finishTest();
      }
    });
  }

  void _checkAnswer() {
    if (_isAnswered) return;
    _cancelTimer();

    final word = _words[_currentIndex];
    final userAnswer = _userAnswer.trim().toLowerCase();
    final correctAnswer = word.wordEs.trim().toLowerCase();

    setState(() {
      _isAnswered = true;
      _totalTests++;

      if (userAnswer == correctAnswer) {
        _isCorrect = true;
        _wordsCorrect++;
      } else {
        _isCorrect = false;
      }

      _saveProgress();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _advanceQuestion();
      });
    });
  }

  Future<void> _saveProgress() async {
    try {
      final existing = await _dbHelper.getUserProgress();
      final progress = UserProgress(
        id: existing?.id ?? 1,
        wordsCorrect: _wordsCorrect,
        totalTests: _totalTests,
        lastSessionDate: DateTime.now().toIso8601String(),
      );
      if (existing != null) {
        await _dbHelper.updateUserProgress(progress);
      } else {
        await _dbHelper.insertUserProgress(progress);
      }
    } catch (e) {}
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _finishTest() {
    _cancelTimer();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Test Completado!', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Palabras correctas: $_wordsCorrect de $_totalTests\n'
          'Porcentaje: ${_totalTests > 0 ? ((_wordsCorrect / _totalTests) * 100).toStringAsFixed(1) : "0%"}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadWords();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cancelTimer();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (!_hasAnyData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_download_outlined, size: 56, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'No hay contenido descargado',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Ve a Inicio y pulsa "Descargar información del día"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
      );
    }

    if (_words.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 56, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'No hay palabras para practicar',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Desliza tarjetas a la izquierda en el Glosario',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
      );
    }

    final word = _words[_currentIndex];
    final progressPercent = _totalTime > 0 ? (_timeRemaining / _totalTime).clamp(0.0, 1.0) : 0.0;
    final progressColor = progressPercent > 0.3 ? const Color(0xFF00E5FF) : progressPercent > 0.15 ? Colors.orange : Colors.red;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercent,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ),
          Text('${_timeRemaining.toStringAsFixed(1)}s', style: TextStyle(fontSize: 12, color: progressColor)),

          Expanded(
            child: Center(
              child: GlassCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(word.wordEn, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _ttsService.speak(word.wordEn),
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Escuchar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A2BE2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      enabled: !_isAnswered,
                      decoration: InputDecoration(
                        hintText: 'Escribe la traducción...',
                        filled: true,
                        fillColor: const Color(0xFF1C1C1E),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.translate, color: Colors.white54),
                        errorText: _isAnswered && !_isCorrect ? 'Respuesta incorrecta' : null,
                        hintStyle: TextStyle(color: Colors.white54),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                      textInputAction: TextInputAction.done,
                      onChanged: (value) => setState(() => _userAnswer = value),
                      onSubmitted: _isAnswered ? null : (value) => _checkAnswer(),
                    ),
                    const SizedBox(height: 16),
                    if (!_isAnswered)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _userAnswer.trim().isEmpty ? null : _checkAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8A2BE2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          child: const Text('Validar Respuesta', style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_isAnswered)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isCorrect ? Icons.check_circle : Icons.cancel, color: _isCorrect ? Colors.green : Colors.red),
                            const SizedBox(width: 8),
                            Text(_isCorrect ? '¡Correcto! 🎉' : 'Correcto: ${word.wordEs}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isCorrect ? Colors.green : Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.black.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Correctas: $_wordsCorrect', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text('Total: $_totalTests', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8A2BE2))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
