import 'package:flutter/material.dart';
import 'package:learning_english/models/fact.dart';
import 'package:learning_english/db/database_helper.dart';
import 'package:learning_english/services/tts_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TtsService _ttsService = TtsService();

  Fact? _currentFact;
  bool _isLoading = true;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _loadFact();
    _ttsService.initialize(
      language: 'en-US',
      speed: 0.5,
      pitch: 1.0,
    ).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar TTS: $e')),
        );
      }
    });
  }

  Future<void> _loadFact() async {
    setState(() => _isLoading = true);
    try {
      final facts = await _dbHelper.getAllFacts();
      if (facts.isEmpty) {
        final testFact = Fact(
          englishText: 'The quick brown fox jumps over the lazy dog near the old river bank.',
          spanishTranslation: 'El rápido zorro marrón salta sobre el perro perezoso cerca del viejo río.',
          difficultyLevel: 'A2',
          publishDate: DateTime.now().toIso8601String(),
          isRead: false,
        );
        await _dbHelper.insertFact(testFact);
        setState(() => _currentFact = testFact);
      } else {
        setState(() => _currentFact = facts.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _speakFact() async {
    if (_currentFact == null) return;
    setState(() => _isSpeaking = true);
    try {
      await _ttsService.speak(_currentFact!.englishText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reproducir audio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  String _cleanWord(String word) {
    return word.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
  }

  Future<void> _showWordDetail(String originalWord) async {
    final cleanedWord = _cleanWord(originalWord);
    final detail = await _dbHelper.lookupWord(cleanedWord);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final wordEn = detail?['word_en'] ?? originalWord;
        final wordEs = detail?['word_es'] ?? 'No disponible';
        final partOfSpeech = detail?['part_of_speech'] ?? '';
        final canAddToVocab = detail != null;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wordEn,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (partOfSpeech.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  partOfSpeech,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const Divider(height: 24),
              Text(
                'Traducción:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                wordEs,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (canAddToVocab)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _addToVocabulary(wordEn, wordEs);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Añadir a Flashcards'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (!canAddToVocab)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Esta palabra no está en el diccionario local.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addToVocabulary(String wordEn, String wordEs) async {
    try {
      final now = DateTime.now();
      final entry = {
        'word': wordEn,
        'translation': wordEs,
        'next_review_date': now.toIso8601String(),
        'interval': 0,
        'ease_factor': 2.5,
      };
      await _dbHelper.insertUserVocabulary(entry);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$wordEn" añadido a tus flashcards ✅'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir flashcard: $e')),
        );
      }
    }
  }

  List<Widget> _buildWordChips() {
    if (_currentFact == null) return [];
    final words = _currentFact!.englishText.split(RegExp(r'\s+'));
    return words.map((word) {
      final cleaned = _cleanWord(word);
      return GestureDetector(
        onTap: () => _showWordDetail(word),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.08),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            word,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.deepPurple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }).toList();
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
        title: const Text(
          'Daily English Facts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.volume_off : Icons.volume_up,
            ),
            onPressed: _isSpeaking ? null : _speakFact,
            tooltip: 'Reproducir audio',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentFact != null) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      shadowColor: Colors.deepPurple.withOpacity(0.15),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _currentFact!.difficultyLevel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (_currentFact!.isRead)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              children: _buildWordChips(),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(
                              'Traducción:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentFact!.spanishTranslation,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
    );
  }
}
