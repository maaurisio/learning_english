import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:learning_english/db/database_helper.dart';
import 'package:learning_english/models/word.dart';
import 'package:learning_english/services/tts_service.dart';
import 'package:learning_english/widgets/flip_card_widget.dart';
import 'package:learning_english/widgets/glass_card.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  GlossaryScreenState createState() => GlossaryScreenState();
}

class GlossaryScreenState extends State<GlossaryScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TtsService _ttsService = TtsService();

  List<Word> _words = [];
  List<Word> _allWords = [];
  bool _isLoading = true;
  bool _hasAnyData = false;
  int _wordsCorrect = 0;

  Offset _dragOffset = Offset.zero;
  late AnimationController _controller;
  bool _exiting = false;
  bool _exitRight = true;
  Offset _startOffset = Offset.zero;
  double _screenWidth = 400;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _controller.addListener(_onExitAnimation);
    _loadWords();
  }

  void reload() {
    _loadWords();
  }

  @override
  void dispose() {
    _controller.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    _controller.stop();
    _exiting = false;
    setState(() => _isLoading = true);
    try {
      final words = await _dbHelper.getUnlearnedWords();
      final allWords = await _dbHelper.getAllWords();
      if (mounted) {
        setState(() {
          _words = words.toList();
          _allWords = allWords.toList();
          _hasAnyData = allWords.isNotEmpty;
          _isLoading = false;
          _dragOffset = Offset.zero;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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

  void _onDismissed(bool right) {
    final word = _words.removeAt(0);
    if (right) {
      _markAsLearned(word);
      setState(() => _wordsCorrect++);
    }
    _dragOffset = Offset.zero;
    _exiting = false;
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_exiting) return;
    setState(() => _dragOffset += details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_exiting) return;
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final threshold = _screenWidth * 0.25;
    final passed = _dragOffset.dx.abs() > threshold || velocityX.abs() > 700;
    _startOffset = _dragOffset;
    if (passed) {
      _exiting = true;
      _exitRight = _dragOffset.dx > 0;
      _controller.reset();
      _controller.forward();
    } else {
      _controller.reset();
      _controller.forward();
    }
  }

  void _onExitAnimation() {
    final target = Offset(
      _exitRight ? _screenWidth + 300 : -(_screenWidth + 300),
      _startOffset.dy,
    );
    setState(() {
      if (_exiting) {
        _dragOffset = Offset.lerp(_startOffset, target, _controller.value)!;
      } else {
        _dragOffset = Offset.lerp(_startOffset, Offset.zero, _controller.value)!;
      }
    });
    if (_controller.isCompleted && _exiting) {
      _controller.reset();
      _onDismissed(_exitRight);
    }
  }

  void _showWordList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => _allWords.isEmpty
            ? const Center(
                child: Text('No hay palabras descargadas', style: TextStyle(color: Colors.white)),
              )
            : ListView.builder(
                controller: scrollController,
                itemCount: _allWords.length,
                itemBuilder: (context, index) {
                  final w = _allWords[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: GlassCard(
                      child: ListTile(
                        title: Text(w.wordEn, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                        subtitle: Text(
                          '${w.wordEs}${w.pronunciation.isNotEmpty ? '  ${w.pronunciation}' : ''}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.volume_up, color: Color(0xFF8A2BE2)),
                          onPressed: () => _speakWord(w.wordEn),
                          tooltip: 'Escuchar',
                        ),
                        trailing: Icon(w.isLearned ? Icons.check_circle : Icons.school, color: w.isLearned ? Colors.green : Colors.white54),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Palabras',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              OutlinedButton.icon(
                onPressed: _allWords.isEmpty ? null : _showWordList,
                icon: const Icon(Icons.list, size: 18),
                label: const Text('Lista de palabras'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8A2BE2),
                  side: const BorderSide(color: Color(0xFF8A2BE2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ),
        ),

        if (!_hasAnyData)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_download_outlined, size: 56, color: Colors.white54),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay contenido descargado',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ve a Inicio y pulsa "Descargar información del día"',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            ),
          )
        else if (_words.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 56, color: Colors.white54),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay palabras pendientes',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ya conoces todas las palabras descargadas',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildSwipeHints(),
                _buildDraggableCard(),
                Positioned(
                  bottom: 24,
                  child: _buildActionsHint(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSwipeHints() {
    final opacity = (math.min(_dragOffset.dx.abs(), 160) / 160).clamp(0.0, 1.0);
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 120),
      child: Container(
        width: _screenWidth * 0.8,
        height: 420,
        decoration: BoxDecoration(
          color: _dragOffset.dx > 0 ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: (_dragOffset.dx > 0 ? Colors.green : Colors.orange).withOpacity(0.4),
          ),
        ),
        child: Center(
          child: Icon(
            _dragOffset.dx > 0 ? Icons.check : Icons.school,
            size: 64,
            color: (_dragOffset.dx > 0 ? Colors.green : Colors.orange).withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Text('Izquierda: practicar', style: TextStyle(color: Colors.white54, fontSize: 12)),
          SizedBox(width: 20),
          Icon(Icons.check, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Text('Derecha: conozco', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDraggableCard() {
    final rotation = (_dragOffset.dx / _screenWidth) * 0.35;
    final opacity = (1 - (_dragOffset.dx.abs() / (_screenWidth * 0.6))).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: _dragOffset,
          child: Transform.rotate(
            angle: rotation,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 420),
              child: SizedBox(
                width: _screenWidth * 0.8,
                child: GlassCard(
                  child: _buildCard(_words.first),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Word word) {
    return FlipCardWidget(
      key: ValueKey(word.id),
      front: _buildCardFront(word),
      back: _buildCardBack(word),
    );
  }

  Widget _buildCardFront(Word word) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          word.wordEn,
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCardBack(Word word) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(word.wordEs, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            word.pronunciation.isNotEmpty ? word.pronunciation : '',
            style: const TextStyle(fontSize: 16, color: Colors.white54, fontStyle: FontStyle.italic),
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
      ),
    );
  }
}
