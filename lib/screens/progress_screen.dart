import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:learning_english/db/database_helper.dart';
import 'package:learning_english/models/offline_download.dart';
import 'package:learning_english/models/tip.dart';
import 'package:learning_english/models/user_progress.dart';
import 'package:learning_english/widgets/glass_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = true;
  UserProgress? _progress;
  List<OfflineDownload> _downloads = [];
  List<Tip> _tips = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final progress = await _dbHelper.getUserProgress();
      final downloads = await _dbHelper.getOfflineDownloads();
      final tips = await _dbHelper.getAllTips();
      if (mounted) {
        setState(() {
          _progress = progress;
          _downloads = downloads;
          _tips = tips;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _downloadData() async {
    try {
      await _dbHelper.seedInitialData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos descargados exitosamente ✅')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar datos: $e')),
        );
      }
    }
  }

  Future<void> _deleteDownload(int id) async {
    try {
      await _dbHelper.deleteOfflineDownload(id);
      if (mounted) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contenido eliminado ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar contenido: $e')),
        );
      }
    }
  }

  Future<void> _resetProgress() async {
    try {
      await _dbHelper.resetUserProgress();
      if (mounted) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progreso reiniciado ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reiniciar progreso: $e')),
        );
      }
    }
  }

  void _navigateToScreen(String routeName) {
    if (routeName == '/') {
      Navigator.pop(context);
    } else {
      Navigator.pushNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progresos y Datos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bienvenido de nuevo,', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('Maurisio', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.deepPurple.withOpacity(0.3),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_progress?.wordsCorrect ?? 0}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green)),
                                const SizedBox(height: 4),
                                Text('Correctas', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${_progress?.totalTests ?? 0}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF8A2BE2))),
                                const SizedBox(height: 4),
                                Text('Tests', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gestión de Contenido Offline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _downloadData,
                              icon: const Icon(Icons.download),
                              label: const Text('Descargar información del día'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8A2BE2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Descargas (${_downloads.length}):', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          if (_downloads.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No hay descargas previas.', style: TextStyle(color: Colors.white54)),
                            ),
                          ..._downloads.map((d) => GlassCard(
                            height: 60,
                            child: ListTile(
                              title: Text(d.dataPackageName, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                              subtitle: Text('${d.downloadDate} · ${d.wordCount} palabras', style: TextStyle(color: Colors.white54)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteDownload(d.id!),
                                tooltip: 'Borrar',
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Píldoras de Conocimiento (${_tips.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          ..._tips.take(5).map((tip) => ListTile(
                            title: Text(tip.title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                            subtitle: Text(tip.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white54)),
                            leading: CircleAvatar(child: Text('${tip.category[0]}', style: const TextStyle(color: Colors.white))),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _resetProgress,
                      icon: const Icon(CupertinoIcons.refresh),
                      label: const Text('Reiniciar Progreso'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
              _bottomNavItem(Icons.menu_book, 'Glosario', '/glossary'),
              _bottomNavItem(Icons.quiz, 'Test', '/test'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem(IconData icon, String label, String route) {
    final isSelected = _currentIndex == _getIndexForRoute(route);
    return GestureDetector(
      onTap: () => _navigateToScreen(route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF8A2BE2) : Colors.white54, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: isSelected ? const Color(0xFF8A2BE2) : Colors.white54)),
        ],
      ),
    );
  }

  int _getIndexForRoute(String route) {
    switch (route) {
      case '/': return 0;
      case '/glossary': return 1;
      case '/test': return 2;
      default: return 0;
    }
  }
}
