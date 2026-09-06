import 'package:flutter/material.dart';
import 'package:learning_english/screens/home_screen.dart';
import 'package:learning_english/screens/progress_screen.dart';
import 'package:learning_english/screens/glossary_screen.dart';
import 'package:learning_english/screens/test_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Learning App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/progress': (context) => const ProgressScreen(),
        '/glossary': (context) => const GlossaryScreen(),
        '/test': (context) => const TestScreen(),
      },
    );
  }
}
