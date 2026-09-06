import 'package:flutter/material.dart';
import 'package:learning_english/db/database_helper.dart';
import 'package:learning_english/models/word.dart';
import 'package:learning_english/services/tts_service.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TtsService _ttsService = TtsService();

  List<Word> _words = [];
  List<Word> _stack = [];
  bool _isLoading = true;
  bool _showLearnedList = false;
  int _wordsCorrect = 0;
  final Map<int, Offset> _dragOffsets = {};

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    try {
      final progress = await _dbHelper.getUserProgress();
      final words = _showLearnedList
          ? await _dbHelper.getLearnedWords()
          : await _dbHelper.getUnlearnedWords();
      if (mounted) {
        setState(() {
          _words = words.toList();
          _stack = words.toList();
          _isLoading = false;
          _wordsCorrect = progress?.wordsCorrect ?? 0;
          _dragOffsets.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _onDragUpdate(int index, Offset delta) {
    setState(() {
      final current = _dragOffsets[index] ?? Offset.zero;
      _dragOffsets[index] = Offset(current.dx + delta.dx, current.dy + delta.dy);
    });
  }

  void _onDragEnd(int index) {
    final offset = _dragOffsets[index] ?? Offset.zero;
    final threshold = 100.0;
    final word = _stack[index];

    if (offset.dx.abs() > threshold) {
      setState(() {
        _dragOffsets.remove(index);
        if (offset.dx > 0) {
          _markAsLearned(word.wordEn);
          _wordsCorrect++;
        }
        _stack.removeAt(index);
      });
      _ttsService.speak(offset.dx > 0 ? 'Great job!' : 'Next word');
    } else {
      setState(() {
        _dragOffsets.remove(index);
      });
    }
  }

  Future<void> _markAsLearned(String wordEn) async {
    try {
      await _dbHelper.markWordAsLearned(wordEn);
      await _dbHelper.insertUserVocabulary({
        'word': wordEn,
        'translation': '',
        'next_review_date': DateTime.now().toIso8601String(),
        'interval': 0,
        'ease_factor': 2.5,
      });
    } catch (e) {}
  }

  void _speakWord(String text) async {
    try {
      await _ttsService.speak(text);
    } catch (e) {}
  }

  void _toggleView() {
    setState(() {
      _showLearnedList = !_showLearnedList;
    });
    _loadWords();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glosario Interactivo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Volver',
        ),
        actions: [
          IconButton(
            icon: Icon(_showLearnedList ? Icons.menu_book : Icons.list),
            onPressed: _toggleView,
            tooltip: _showLearnedList ? 'Ver Tarjetas' : 'Ver Listado',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stack.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books, size: 64, color: Colors.deepPurple.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        _showLearnedList ? '¡Has aprendido todas las palabras!' : 'Desliza las tarjetas para aprender',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadWords,
                        icon: const Icon(Icons.refresh),
                        label: Text(_showLearnedList ? 'Volver a la Pila' : 'Recargar'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    for (int i = 0; i < _stack.length; i++)
                      _buildCard(i, _stack[i]),
                  ],
                ),
      bottomNavigationBar: _stack.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('Pendientes', '${_stack.length}'),
                  _stat('Aprendidas', '$_wordsCorrect'),
                  ElevatedButton.icon(
                    onPressed: () => _speakWord(_stack.last.wordEn),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Escuchar'),
                    style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.deepPurple),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildCard(int index, Word word) {
    final offset = _dragOffsets[index] ?? Offset.zero;
    final screenWidth = MediaQuery.of(context).size.width;
    final rotation = (offset.dx / screenWidth) * 0.3;
    final opacity = (offset.dx.abs() / screenWidth).clamp(0.0, 1.0);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      left: 16,
      right: 16,
      bottom: 0,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) => _onDragUpdate(index, details.delta),
        onHorizontalDragEnd: (details) => _onDragEnd(index),
        child: Opacity(
          opacity: 1.0 - (index == 0 ? opacity * 0.3 : 0),
          child: Transform.translate(
            offset: offset,
            child: Transform.rotate(
              angle: rotation,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _showLearnedList
                        ? [Colors.green.shade100, Colors.green.shade50]
                        : [Colors.deepPurple, Colors.deepPurpleAccent],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _speakWord(word.wordEn),
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(word.wordEn,
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          Text(
                            _showLearnedList ? '✅ Aprendida' : 'Desliza → o toca para escuchar',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _hint(Icons.arrow_back_ios, 'Nueva', Colors.orange),
                              _hint(Icons.arrow_forward_ios, 'Aprendida', Colors.green),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hint(IconData icon, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _stat(String label, String value) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ]);
  }
}
