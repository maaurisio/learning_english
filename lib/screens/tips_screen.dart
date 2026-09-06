import 'dart:math';
import 'package:flutter/material.dart';
import 'package:learning_english/db/database_helper.dart';
import 'package:learning_english/models/bilingual_item.dart';
import 'package:learning_english/services/tts_service.dart';
import 'package:learning_english/widgets/glass_card.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  TipsScreenState createState() => TipsScreenState();
}

class TipsScreenState extends State<TipsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TtsService _ttsService = TtsService();
  final Random _random = Random();

  List<BilingualItem> _tips = [];
  List<BilingualItem> _curiosities = [];
  BilingualItem? _currentTip;
  BilingualItem? _currentCuriosity;
  bool _isLoading = true;
  bool _hasAnyData = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void reload() {
    _loadData();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final tips = await _dbHelper.getEnglishTips();
      final curiosities = await _dbHelper.getCuriosities();
      if (mounted) {
        setState(() {
          _tips = tips;
          _curiosities = curiosities;
          _hasAnyData = tips.isNotEmpty || curiosities.isNotEmpty;
          _currentTip = tips.isEmpty ? null : tips[_random.nextInt(tips.length)];
          _currentCuriosity = curiosities.isEmpty ? null : curiosities[_random.nextInt(curiosities.length)];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextTip() {
    if (_tips.isEmpty) return;
    setState(() {
      BilingualItem next;
      do {
        next = _tips[_random.nextInt(_tips.length)];
      } while (next.id == _currentTip?.id && _tips.length > 1);
      _currentTip = next;
    });
  }

  void _nextCuriosity() {
    if (_curiosities.isEmpty) return;
    setState(() {
      BilingualItem next;
      do {
        next = _curiosities[_random.nextInt(_curiosities.length)];
      } while (next.id == _currentCuriosity?.id && _curiosities.length > 1);
      _currentCuriosity = next;
    });
  }

  void _speak(String text) async {
    try {
      await _ttsService.speak(text);
    } catch (e) {}
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionHeader('Tips en Inglés', 'Frases y contexto', Icons.tips_and_updates, const Color(0xFF00E5FF)),
          const SizedBox(height: 10),
          Expanded(
            child: _buildBilingualCard(
              item: _currentTip,
              accent: const Color(0xFF00E5FF),
              onNext: _nextTip,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('¿Sabías que...?', 'Cultura general', Icons.lightbulb, const Color(0xFFFFB300)),
          const SizedBox(height: 10),
          Expanded(
            child: _buildBilingualCard(
              item: _currentCuriosity,
              accent: const Color(0xFFFFB300),
              onNext: _nextCuriosity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white54)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBilingualCard({
    required BilingualItem? item,
    required Color accent,
    required VoidCallback onNext,
  }) {
    return GlassCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: item == null
            ? Center(
                child: Text(
                  'No hay contenido disponible para esta sección',
                  style: TextStyle(fontSize: 15, color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accent.withOpacity(0.4)),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        color: accent,
                        tooltip: 'Escuchar',
                        onPressed: () => _speak(item.englishText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: onNext,
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          final offset =
                              Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(position: offset, child: child),
                          );
                        },
                        child: SingleChildScrollView(
                          key: ValueKey(item.id),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  item.englishText,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                Container(height: 1, color: Colors.white.withOpacity(0.15)),
                                const SizedBox(height: 14),
                                Text(
                                  item.spanishTranslation,
                                  style: const TextStyle(fontSize: 15, color: Colors.white54, height: 1.4),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.shuffle, size: 18),
                    label: const Text('Mostrar otro'),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}