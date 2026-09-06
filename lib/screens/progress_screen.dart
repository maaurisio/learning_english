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

  Future<void> _downloadDailyData() async {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return ListView(
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
                      const Text('Correctas', style: TextStyle(color: Colors.white, fontSize: 14)),
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
                      const Text('Tests', style: TextStyle(color: Colors.white, fontSize: 14)),
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
                    onPressed: _downloadDailyData,
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
                const Text('Descargas:', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
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
                const Text('Píldoras de Conocimiento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
    );
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
}
