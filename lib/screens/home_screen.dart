import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learning_english/db/database_helper.dart';
import 'package:learning_english/models/fact.dart';
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
  bool _isPlaying = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
                Text(pronunciation, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic)),
              ],
              const Divider(height: 24),
              Text('Traducción:', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
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
                      foregroundColor: Colors.white, backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            color: Colors.deepPurple.withOpacity(0.08),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(word, style: const TextStyle(fontSize: 16, color: Colors.deepPurple, fontWeight: FontWeight.w500)),
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
    Navigator.pop(context);
    Navigator.pushNamed(context, routeName);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('English Daily Facts', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.volume_off : Icons.volume_up),
            onPressed: _isPlaying ? null : _speakFact,
            tooltip: 'Reproducir audio',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              child: const Text('Menú', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            _drawerItem(Icons.home, 'Inicio', '/'),
            _drawerItem(Icons.bar_chart, 'Progresos y Datos', '/progress'),
            _drawerItem(Icons.menu_book, 'Glosario', '/glossary'),
            _drawerItem(Icons.quiz, 'Modo Test', '/test'),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Salir', style: TextStyle(color: Colors.red)),
              onTap: _exitApp,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentFact != null) ...[
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.deepPurple, Colors.deepPurpleAccent]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(_currentFact!.difficultyLevel,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ),
                                if (_currentFact!.isRead)
                                  const Icon(Icons.check_circle, color: Colors.green, size: 22),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Wrap(children: _buildWordChips()),
                            const SizedBox(height: 24),
                            const Divider(color: Colors.white70),
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
                  ],
                  if (_currentFact != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _speakFact,
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Escuchar en voz alta'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _drawerItem(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: () => _navigateToScreen(route),
    );
  }
}
