import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:learning_english/models/fact.dart';
import 'package:learning_english/models/word.dart';
import 'package:learning_english/models/tip.dart';
import 'package:learning_english/models/user_progress.dart';
import 'package:learning_english/models/offline_download.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const int _dbVersion = 3;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'learning_english.db');

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE dictionary ADD COLUMN pronunciation TEXT DEFAULT \'\'');
      await db.execute('ALTER TABLE dictionary ADD COLUMN audio_path TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE dictionary ADD COLUMN is_learned INTEGER DEFAULT 0');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE daily_facts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        english_text TEXT NOT NULL,
        spanish_translation TEXT NOT NULL,
        difficulty TEXT,
        publish_date TEXT,
        is_read INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE dictionary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_en TEXT NOT NULL,
        word_es TEXT NOT NULL,
        pronunciation TEXT DEFAULT '',
        audio_path TEXT,
        is_learned INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE tips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE offline_downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        download_date TEXT NOT NULL,
        data_package_name TEXT NOT NULL,
        word_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE user_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        words_correct INTEGER DEFAULT 0,
        total_tests INTEGER DEFAULT 0,
        last_session_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE user_vocabulary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        translation TEXT NOT NULL,
        next_review_date TEXT,
        interval INTEGER,
        ease_factor REAL
      )
    ''');
  }

  Future<void> closeDB() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<int> insertFact(Fact fact) async {
    final db = await database;
    return await db.insert('daily_facts', fact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Fact>> getAllFacts() async {
    final db = await database;
    final result = await db.query('daily_facts');
    return result.map((map) => Fact.fromMap(map)).toList();
  }

  Future<List<Fact>> getUnreadFacts() async {
    final db = await database;
    final result = await db.query('daily_facts', where: 'is_read = ?', whereArgs: [0]);
    return result.map((map) => Fact.fromMap(map)).toList();
  }

  Future<void> markFactAsRead(int id) async {
    final db = await database;
    await db.update('daily_facts', {'is_read': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Word>> getAllWords() async {
    final db = await database;
    final result = await db.query('dictionary');
    return result.map((map) => Word.fromMap(map)).toList();
  }

  Future<List<Word>> getUnlearnedWords() async {
    final db = await database;
    final result = await db.query('dictionary', where: 'is_learned = ?', whereArgs: [0]);
    return result.map((map) => Word.fromMap(map)).toList();
  }

  Future<List<Word>> getLearnedWords() async {
    final db = await database;
    final result = await db.query('dictionary', where: 'is_learned = ?', whereArgs: [1]);
    return result.map((map) => Word.fromMap(map)).toList();
  }

  Future<int> insertWord(Word word) async {
    final db = await database;
    return await db.insert('dictionary', word.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertWords(List<Word> words) async {
    final db = await database;
    int count = 0;
    for (var word in words) {
      count += await db.insert('dictionary', word.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return count;
  }

  Future<Word?> lookupWord(String wordEn) async {
    final db = await database;
    final result = await db.query('dictionary', where: 'LOWER(word_en) = ?', whereArgs: [wordEn.toLowerCase()]);
    if (result.isNotEmpty) return Word.fromMap(result.first);
    return null;
  }

  Future<void> markWordAsLearned(String wordEn) async {
    final db = await database;
    await db.update('dictionary', {'is_learned': 1}, where: 'LOWER(word_en) = ?', whereArgs: [wordEn.toLowerCase()]);
  }

  Future<void> markWordAsUnlearned(String wordEn) async {
    final db = await database;
    await db.update('dictionary', {'is_learned': 0}, where: 'LOWER(word_en) = ?', whereArgs: [wordEn.toLowerCase()]);
  }

  Future<List<Tip>> getAllTips() async {
    final db = await database;
    final result = await db.query('tips');
    return result.map((map) => Tip.fromMap(map)).toList();
  }

  Future<int> insertTip(Tip tip) async {
    final db = await database;
    return await db.insert('tips', tip.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> insertTips(List<Tip> tips) async {
    final db = await database;
    int count = 0;
    for (var tip in tips) {
      count += await db.insert('tips', tip.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return count;
  }

  Future<List<OfflineDownload>> getOfflineDownloads() async {
    final db = await database;
    final result = await db.query('offline_downloads', orderBy: 'download_date DESC');
    return result.map((map) => OfflineDownload.fromMap(map)).toList();
  }

  Future<int> insertOfflineDownload(OfflineDownload download) async {
    final db = await database;
    return await db.insert('offline_downloads', download.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteOfflineDownload(int id) async {
    final db = await database;
    await db.delete('offline_downloads', where: 'id = ?', whereArgs: [id]);
  }

  Future<UserProgress?> getUserProgress() async {
    final db = await database;
    final result = await db.query('user_progress');
    if (result.isNotEmpty) return UserProgress.fromMap(result.first);
    return null;
  }

  Future<int> insertUserProgress(UserProgress progress) async {
    final db = await database;
    return await db.insert('user_progress', progress.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateUserProgress(UserProgress progress) async {
    final db = await database;
    return await db.update('user_progress', progress.toMap(), where: 'id = ?', whereArgs: [progress.id]);
  }

  Future<void> resetUserProgress() async {
    final db = await database;
    await db.delete('user_progress');
  }

  Future<void> clearDictionary() async {
    final db = await database;
    await db.delete('dictionary');
  }

  Future<void> clearTips() async {
    final db = await database;
    await db.delete('tips');
  }

  Future<void> clearFacts() async {
    final db = await database;
    await db.delete('daily_facts');
  }

  Future<int> insertUserVocabulary(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('user_vocabulary', entry, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> seedInitialData() async {
    final englishWords = [
      'abandon', 'ability', 'abroad', 'absence', 'absolutely', 'academic',
      'accept', 'access', 'accident', 'accommodate', 'accompany', 'accomplish',
      'account', 'accurate', 'achieve', 'acid', 'acknowledge', 'acquire',
      'across', 'act', 'action', 'active', 'actually', 'adapt', 'adequate',
      'adjacent', 'adjust', 'administer', 'admit', 'adopt', 'adult',
      'advance', 'advantage', 'adventure', 'advertise', 'advice', 'advise',
      'aesthetic', 'affect', 'afford', 'afraid', 'aggressive', 'agree',
      'ahead', 'aid', 'aim', 'air', 'aircraft', 'algorithm', 'alias',
      'allergic', 'allocate', 'allow', 'aluminum', 'always', 'amateur',
      'amazing', 'ambiguous', 'ambition', 'amend', 'amount', 'amuse',
      'analyse', 'anchor', 'ancient', 'anger', 'angle', 'angry', 'announce',
      'annual', 'annoy', 'anxiety', 'anyone', 'anything', 'apparent',
      'appeal', 'appear', 'apple', 'apply', 'appreciate', 'approach',
      'appropriate', 'approve', 'argue', 'arise', 'arm', 'armed', 'aroma',
      'around', 'arrange', 'arrest', 'arrive', 'arrow', 'art', 'article',
      'artist', 'artistic', 'as', 'aspect', 'assess', 'asset', 'assign',
      'assist', 'assume', 'athlete', 'atom', 'attack', 'attempt', 'attend',
      'attention', 'attitude', 'attract', 'attribute', 'audience', 'audit',
      'authentic', 'author', 'authority', 'automate', 'available', 'average',
      'avoid', 'award', 'aware', 'awful', 'awkward', 'axis',
      'baby', 'back', 'bacteria', 'balance', 'balcony', 'ball', 'bank',
      'barely', 'barrier', 'base', 'basic', 'basis', 'basket', 'battle',
      'beach', 'beam', 'bean', 'bear', 'beat', 'beautiful', 'because',
      'become', 'bed', 'bedroom', 'bee', 'before', 'begin', 'behavior',
      'behind', 'believe', 'belong', 'below', 'belt', 'bench', 'benefit',
      'best', 'bet', 'better', 'between', 'beyond', 'bias', 'bicycle',
      'bid', 'big', 'bill', 'binary', 'bind', 'bird', 'birth', 'bitter',
      'black', 'blade', 'blame', 'blanket', 'blast', 'bleed', 'blind',
      'block', 'blood', 'blow', 'blue', 'board', 'boast', 'boat', 'body',
      'bomb', 'bone', 'book', 'boost', 'border', 'boring', 'borrow', 'boss',
      'both', 'bother', 'bottom', 'bounce', 'bound', 'brain', 'branch',
      'brand', 'break', 'breath', 'brick', 'bridge', 'brief', 'bring',
      'broad', 'broadcast', 'brush', 'bubble', 'budget', 'bug', 'build',
      'bulky', 'bull', 'bullet', 'bundle', 'burden', 'burger', 'burn',
      'burst', 'bus', 'bush', 'business', 'busy', 'but', 'butter', 'button',
      'buyer', 'buzz', 'byte',
    ];

    final spanishTranslations = [
      'abandonar', 'habilidad', 'en el extranjero', 'ausencia', 'absolutamente',
      'académico', 'aceptar', 'acceso', 'accidente', 'acomodar', 'acompañar',
      'lograr', 'cuenta', 'preciso', 'logro', 'ácido', 'reconocer', 'adquirir',
      'a través de', 'acto', 'acción', 'activo', 'realmente', 'adaptar',
      'adecuado', 'adyacente', 'ajustar', 'administrar', 'admitir', 'adoptar',
      'adulto', 'avanzar', 'ventaja', 'aventura', 'anunciar', 'asesoramiento',
      'asesorar', 'estético', 'afectar', 'permitir', 'tener miedo',
      'agresivo', 'estar de acuerdo', 'por delante', 'ayuda', 'punto', 'aire',
      'avión', 'algoritmo', 'alias', 'alérgico', 'asignar', 'permitir',
      'aluminio', 'siempre', 'aficionado', 'asombroso', 'ambiguo', 'ambición',
      'enmendar', 'cantidad', 'divertir', 'analizar', 'ancla', 'antiguo',
      'ira', 'ángulo', 'enojado', 'anunciar', 'anual', 'molestar', 'ansiedad',
      'alguien', 'algo', 'aparente', 'apelación', 'parecer', 'manzana',
      'aplicar', 'apreciar', 'enfoque', 'apropiado', 'aprobar', 'discutir',
      'surgir', 'brazo', 'armado', 'aroma', 'alrededor', 'organizar', 'detener',
      'llegar', 'flecha', 'arte', 'artículo', 'artista', 'artístico', 'como',
      'aspecto', 'evaluar', 'activo', 'asignar', 'asistir', 'suponer',
      'atleta', 'átomo', 'ataque', 'intento', 'asistir', 'atención', 'actitud',
      'atraer', 'atributo', 'público', 'auditoría', 'auténtico', 'autor',
      'autoridad', 'automatizar', 'disponible', 'promedio', 'evitar', 'galardón',
      'consciente', 'horrible', 'incómodo', 'eje', 'bebé', 'atrás',
      'bacteria', 'equilibrio', 'balcón', 'pelota', 'banco', 'apenas',
      'barrera', 'base', 'básico', 'fundamento', 'canasta', 'batalla',
      'playa', 'haz', 'frijol', 'oso', 'golpe', 'hermoso', 'porque',
      'convertirse', 'cama', 'dormitorio', 'abeja', 'antes de', 'comenzar',
      'comportamiento', 'detrás', 'creer', 'pertenecer', 'debajo', 'cinturón',
      'bancada', 'beneficio', 'mejor', 'apuesta', 'mejor', 'entre', 'más allá',
      'sesgo', 'bicicleta', 'oferta', 'grande', 'factura', 'binario', 'atar',
      'pájaro', 'nacimiento', 'amargo', 'negro', 'hoja', 'culpar', 'manta',
      'explosión', 'sangrar', 'ciego', 'bloqueo', 'sangre', 'soplar', 'azul',
      'tablero', 'presumir', 'barco', 'cuerpo', 'bomba', 'hueso', 'libro',
      'impulsar', 'frontera', 'aburrido', 'prestar', 'jefe', 'ambos', 'molestar',
      'fondo', 'rebotar', 'atado', 'cerebro', 'rama', 'marca', 'romper',
      'respiración', 'ladrillo', 'puente', 'breve', 'traer', 'amplio',
      'transmitir', 'cepillo', 'burbuja', 'presupuesto', 'insecto', 'construir',
      'voluminoso', 'toro', 'bala', 'paquete', 'carga', 'hamburguesa', 'quemar',
      'ráfaga', 'autobús', 'arbusto', 'negocio', 'ocupado', 'pero', 'mantequilla',
      'botón', 'comprador', 'zumbido', 'byte',
    ];

    final random = DateTime.now().millisecondsSinceEpoch;
    final rng = _SimpleRandom(random);

    final wordList = <Word>[];
    for (int i = 0; i < 100 && i < englishWords.length; i++) {
      final idx = rng.nextInt(englishWords.length);
      wordList.add(Word(
        wordEn: englishWords[idx],
        wordEs: spanishTranslations[idx],
        pronunciation: '/${_getPhonetic(englishWords[idx])}/',
      ));
    }

    await insertWords(wordList);

    final tips = <Tip>[
      Tip(title: 'Memoria Espaciada', content: 'Repasa las palabras en intervalos crecientes: 1 día, 3 días, 7 días, 14 días.', category: 'Study'),
      Tip(title: 'Inmersión Diaria', content: 'Escucha inglés al menos 15 minutos al día. La constancia supera a la intensidad.', category: 'Listening'),
      Tip(title: 'Aprende en Contexto', content: 'No memorices palabras aisladas. Aprende frases completas y oraciones reales.', category: 'Vocabulary'),
      Tip(title: 'Práctica Activa', content: 'Escribe y habla las palabras en voz alta. La activación motora refuerza el aprendizaje.', category: 'Speaking'),
      Tip(title: 'Raíces y Prefijos', content: 'Aprender raíces latinas y griegas te ayuda a deducir el significado de palabras nuevas.', category: 'Grammar'),
      Tip(title: 'Error es Oportunidad', content: 'Cada error es una señal de qué necesitas practicar más. No te frustres, sigue avanzando.', category: 'Motivation'),
      Tip(title: 'Flashcards Inteligentes', content: 'Usa repetición espaciada. Si aciertas, aumenta el intervalo. Si fallas, repite pronto.', category: 'Study'),
      Tip(title: 'Consume Contenido Real', content: 'Lee noticias, escucha podcasts y mira series en inglés. El lenguaje real es más memorable.', category: 'Immersion'),
      Tip(title: 'Meta Semanal', content: 'Establece 5-10 palabras nuevas por semana. Pequeñas metas son más sostenibles.', category: 'Goal'),
      Tip(title: 'Revisa y Conecta', content: 'Conecta palabras nuevas con imágenes, emociones o historias personales.', category: 'Memory'),
    ];

    await insertTips(tips);

    final fact = Fact(
      englishText: 'Knowledge is power, and consistent practice is the key to mastering any language.',
      spanishTranslation: 'El conocimiento es poder, y la práctica constante es la clave para dominar cualquier idioma.',
      difficultyLevel: 'B1',
      publishDate: DateTime.now().toIso8601String(),
      isRead: false,
    );
    await insertFact(fact);

    final progress = UserProgress(wordsCorrect: 0, totalTests: 0, lastSessionDate: DateTime.now().toIso8601String());
    await insertUserProgress(progress);

    final download = OfflineDownload(
      downloadDate: DateTime.now().toIso8601String(),
      dataPackageName: 'initial_package',
      wordCount: 100,
    );
    await insertOfflineDownload(download);
  }

  String _getPhonetic(String word) {
    final map = <String, String>{
      'abandon': 'əˈbændən', 'ability': 'əˈbɪlɪti', 'abroad': 'əˈbrɔːd',
      'absence': 'ˈæbsəns', 'absolutely': 'ˈæbsəluːtli', 'academic': 'ˌækəˈdɛmɪk',
      'accept': 'əkˈsept', 'access': 'ˈækses', 'accident': 'ˈæksɪdənt',
      'accommodate': 'əˈkɒmədeɪt', 'accompany': 'əˈkʌmpəni', 'accomplish': 'əˈkɒmplɪʃ',
      'account': 'əˈkaʊnt', 'accurate': 'ˈækjərət', 'achieve': 'əˈtʃiːv',
      'acid': 'ˈæsɪd', 'acknowledge': 'əkˈnɒlɪdʒ', 'acquire': 'əˈkwaɪə',
      'across': 'əˈkrɒs', 'act': 'ækt', 'action': 'ˈækʃən', 'active': 'ˈæktɪv',
      'actually': 'ˈæktʃuəli', 'adapt': 'əˈdæpt', 'adequate': 'ˈædɪkwɪt',
      'adjacent': 'əˈdʒeɪsənt', 'adjust': 'əˈdʒʌst', 'administer': 'ədˈmɪnɪstə',
      'admit': 'ədˈmɪt', 'adopt': 'əˈdɒpt', 'adult': 'ˈædʌlt',
      'advance': 'ədˈvæns', 'advantage': 'ədˈvɑːntɪdʒ', 'adventure': 'ædˈventʃə',
    };
    return map[word.toLowerCase()] ?? word.toLowerCase();
  }
}

class _SimpleRandom {
  final int _seed;
  int _state;

  _SimpleRandom(int seed) : _seed = seed, _state = seed;

  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return (_state % max);
  }
}
