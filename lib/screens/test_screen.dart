import 'dart:async';
import 'package:flutter/material.dart';
import 'package:learning_english/db/database_helper.dart';
import 'package:learning_english/models/word.dart';
import 'package:learning_english/models/user_progress.dart';
import 'package:learning_english/services/tts_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
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
  Timer? _timer;
  double _timeRemaining = 0;
  double _totalTime = 0;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    try {
      final words = await _dbHelper.getAllWords();
      if (mounted && words.isNotEmpty) {
        setState(() {
          _words = words;
          _currentIndex = 0;
          _wordsCorrect = 0;
          _totalTests = 0;
          _isLoading = false;
          _isAnswered = false;
          _isCorrect = false;
          _userAnswer = '';
        });
        _startNextQuestion();
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay palabras en el glosario. Descarga datos primero.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar palabras: $e')),
        );
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
    if (_isLoading || _words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modo Test', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final word = _words[_currentIndex];
    final progressPercent = _totalTime > 0 ? (_timeRemaining / _totalTime).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Test', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _cancelTimer();
            Navigator.pop(context);
          },
          tooltip: 'Volver',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('${_currentIndex + 1}/${_words.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 10,
            width: double.infinity,
            color: Colors.grey[300],
            child: LinearProgressIndicator(
              value: progressPercent,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progressPercent > 0.3 ? Colors.green : progressPercent > 0.15 ? Colors.orange : Colors.red,
              ),
            ),
          ),
          Text('${_timeRemaining.toStringAsFixed(1)}s', style: TextStyle(fontSize: 12, color: progressPercent > 0.3 ? Colors.green : Colors.orange)),

          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(word.wordEn, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _ttsService.speak(word.wordEn),
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Escuchar'),
                      style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.deepPurple),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      enabled: !_isAnswered,
                      decoration: InputDecoration(
                        hintText: 'Escribe la traducción...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        prefixIcon: const Icon(Icons.translate),
                        errorText: _isAnswered && !_isCorrect ? 'Respuesta incorrecta' : null,
                      ),
                      style: const TextStyle(fontSize: 18),
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
                          style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: const Text('Validar Respuesta', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_isAnswered)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
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
            color: Colors.deepPurple.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Correctas: $_wordsCorrect', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text('Total: $_totalTests', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
