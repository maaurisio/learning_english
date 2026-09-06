import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:learning_english/db/database_helper.dart';
import 'package:learning_english/models/word.dart';
import 'package:learning_english/services/tts_service.dart';
import 'package:learning_english/widgets/flip_card_widget.dart';
import 'package:learning_english/widgets/glass_card.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TtsService _ttsService = TtsService();

  List<Word> _words = [];
  bool _isLoading = true;
  int _wordsCorrect = 0;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    try {
      final progress = await _dbHelper.getUserProgress();
      final words = await _dbHelper.getUnlearnedWords();
      if (mounted) {
        setState(() {
          _words = words.toList();
          _isLoading = false;
          _wordsCorrect = progress?.wordsCorrect ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _markAsLearned(Word word) async {
    try {
      await _dbHelper.markWordAsLearned(word.wordEn);
      await _dbHelper.insertUserVocabulary({
        'word': word.wordEn,
        'translation': word.wordEs,
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

  void _onDismissed(Word word, DismissDirection direction) {
    if (direction == DismissDirection.endToStart) {
      _markAsLearned(word);
      setState(() => _wordsCorrect++);
    }
    setState(() => _words.remove(word));
  }

  Future<void> _showPendingWordsSheet() async {
    final learnedWords = await _dbHelper.getLearnedWords();
    showModalBottomSheet(
      context: context,
      builder: (context) => learnedWords.isEmpty
          ? const Center(child: Text('No hay palabras aprendidas aún', style: TextStyle(color: Colors.white)))
          : ListView.builder(
              itemCount: learnedWords.length,
              itemBuilder: (context, index) {
                final w = learnedWords[index];
                return ListTile(
                  title: Text(w.wordEn, style: const TextStyle(fontSize: 18, color: Colors.white)),
                  subtitle: Text(w.wordEs, style: TextStyle(color: Colors.white.withOpacity(0.54))),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_words.isEmpty) {
      return const Center(
        child: Text(
          'No hay palabras pendientes',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Dismissible(
          key: ValueKey(_words.first.id),
          direction: DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            _onDismissed(_words.first, direction);
            return true;
          },
          background: Container(
            color: Colors.green,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.check, color: Colors.white, size: 40),
          ),
          secondaryBackground: Container(
            color: Colors.orange,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 40),
          ),
          child: GlassCard(
            child: _buildCard(_words.first),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Word word) {
    return FlipCardWidget(
      front: _buildCardFront(word),
      back: _buildCardBack(word),
    );
  }

  Widget _buildCardFront(Word word) {
    return Center(
      child: Text(
        word.wordEn,
        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCardBack(Word word) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(word.wordEs, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          word.pronunciation.isNotEmpty ? word.pronunciation : '',
          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.54), fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _speakWord(word.wordEn),
          icon: const Icon(Icons.volume_up),
          label: const Text('Escuchar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8A2BE2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
      ],
    );
  }
}
