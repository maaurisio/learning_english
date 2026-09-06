import 'package:flutter/material.dart';
import 'package:learning_english/db/database_helper.dart';
import 'package:learning_english/models/offline_download.dart';
import 'package:learning_english/models/user_progress.dart';
import 'package:learning_english/models/tip.dart';
import 'package:learning_english/screens/home_screen.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    }
  }

  Future<void> _downloadData() async {
    try {
      await _dbHelper.seedInitialData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos descargados exitosamente ✅')));
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al descargar datos: $e')));
      }
    }
  }

  Future<void> _deleteDownload(int id) async {
    try {
      await _dbHelper.deleteOfflineDownload(id);
      if (mounted) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contenido eliminado ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar contenido: $e')));
      }
    }
  }

  Future<void> _resetProgress() async {
    try {
      await _dbHelper.resetUserProgress();
      if (mounted) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progreso reiniciado ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al reiniciar progreso: $e')));
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
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              child: const Text('Menú', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.deepPurple),
              title: const Text('Inicio'),
              onTap: () => _navigateToScreen('/'),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.deepPurple),
              title: const Text('Glosario'),
              onTap: () => _navigateToScreen('/glossary'),
            ),
            ListTile(
              leading: const Icon(Icons.quiz, color: Colors.deepPurple),
              title: const Text('Modo Test'),
              onTap: () => _navigateToScreen('/test'),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Salir', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
              },
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
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estadísticas de Progreso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statCard('Correctas', '${_progress?.wordsCorrect ?? 0}', Colors.green),
                              _statCard('Tests', '${_progress?.totalTests ?? 0}', Colors.blue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gestión de Contenido Offline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _downloadData,
                              icon: const Icon(Icons.download),
                              label: const Text('Descargar información del día'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, backgroundColor: Colors.deepPurple,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Descargas (${_downloads.length}):', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          if (_downloads.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No hay descargas previas.', style: TextStyle(color: Colors.grey)),
                            ),
                          ..._downloads.map((d) => Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(d.dataPackageName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${d.downloadDate} · ${d.wordCount} palabras'),
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
                  const SizedBox(height: 20),

                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Píldoras de Conocimiento (${_tips.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ..._tips.take(5).map((tip) => ListTile(
                            title: Text(tip.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(tip.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                            leading: CircleAvatar(child: Text('${tip.category[0]}')),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _resetProgress,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reiniciar Progreso'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
