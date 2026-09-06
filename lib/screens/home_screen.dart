import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learning_english/db/database_helper.dart';
import 'package:learning_english/models/fact.dart';
import 'package:learning_english/services/tts_service.dart';
import 'package:learning_english/widgets/glass_card.dart';

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
  bool _isPlaying = false;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFact();
    _ttsService.init().catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar TTS: $e')),
        );
      }
    });
    _ttsService.addListener(_onTtsStateChange);
  }

  Future<void> _refreshData() async {
    try {
      final facts = await _dbHelper.getAllFacts();
      if (mounted && facts.isNotEmpty) {
        setState(() => _currentFact = facts.first);
      }
    } catch (e) {
      // Silently handle
    }
  }

  void _onTtsStateChange() {
    if (mounted) {
      setState(() => _isPlaying = _ttsService.isPlaying);
    }
  }

  Future<void> _loadFact() async {
    setState(() => _isLoading = true);
    try {
      final facts = await _dbHelper.getAllFacts();
      if (facts.isEmpty) {
        await _dbHelper.seedInitialData();
        final factsAfter = await _dbHelper.getAllFacts();
        if (mounted) setState(() => _currentFact = factsAfter.isNotEmpty ? factsAfter.first : null);
      } else {
        if (mounted) setState(() => _currentFact = facts.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _speakFact() async {
    if (_currentFact == null) return;
    try {
      await _ttsService.speak(_currentFact!.englishText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reproducir audio: $e')),
        );
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
        final wordEn = detail?.wordEn ?? originalWord;
        final wordEs = detail?.wordEs ?? 'No disponible';
        final pronunciation = detail?.pronunciation ?? '';
        final canAddToVocab = detail != null;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(wordEn, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              if (pronunciation.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(pronunciation, style: TextStyle(fontSize: 14, color: Colors.white70, fontStyle: FontStyle.italic)),
              ],
              const Divider(height: 24),
              Text('Traducción:', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(wordEs, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
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
                      backgroundColor: const Color(0xFF8A2BE2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              if (!canAddToVocab)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Esta palabra no está en el diccionario local.',
                    style: TextStyle(fontSize: 14, color: Colors.orange[700], fontStyle: FontStyle.italic)),
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
      final entry = {'word': wordEn, 'translation': wordEs, 'next_review_date': now.toIso8601String(), 'interval': 0, 'ease_factor': 2.5};
      await _dbHelper.insertUserVocabulary(entry);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$wordEn" añadido a tus flashcards ✅'), duration: const Duration(seconds: 2)),
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
      return GestureDetector(
        onTap: () => _showWordDetail(word),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF8A2BE2).withOpacity(0.15),
            border: Border.all(color: const Color(0xFF8A2BE2).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(word, style: const TextStyle(fontSize: 16, color: const Color(0xFF8A2BE2), fontWeight: FontWeight.w500)),
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    _ttsService.removeListener();
    _ttsService.dispose();
    super.dispose();
  }

  void _navigateToScreen(String routeName) {
    if (routeName == '/') {
      Navigator.pop(context);
    } else {
      Navigator.pushNamed(context, routeName);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('English Daily Facts', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.volume_off : Icons.volume_up),
            onPressed: _isPlaying ? null : _speakFact,
            tooltip: 'Reproducir audio',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentFact != null) ...[
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8A2BE2).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(_currentFact!.difficultyLevel,
                                    style: const TextStyle(color: Color(0xFF8A2BE2), fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                                if (_currentFact!.isRead)
                                  const Icon(Icons.check_circle, color: Colors.green, size: 22),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Wrap(children: _buildWordChips()),
                            const SizedBox(height: 24),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 12),
                            Text('Traducción:', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(_currentFact!.spanishTranslation,
                              style: const TextStyle(fontSize: 17, color: Colors.white, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _speakFact,
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Escuchar en voz alta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A2BE2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomNavItem(Icons.home, 'Inicio', '/'),
              _bottomNavItem(Icons.bar_chart, 'Progreso', '/progress'),
              _bottomNavItem(Icons.menu_book, 'Glosario', '/glossary'),
              _bottomNavItem(Icons.quiz, 'Test', '/test'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem(IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () {
        if (route == '/') Navigator.pop(context);
        else Navigator.pushNamed(context, route);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.white54)),
        ],
      ),
    );
  }
}
