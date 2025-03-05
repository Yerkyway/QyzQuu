import 'package:flutter/material.dart';
import 'package:qyz_quu/pages/menu_page.dart';
import 'package:qyz_quu/pages/game_page.dart'; // Import the correct GameScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Қыз қуу',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const MenuPage(),
        '/game': (context) => const GameScreen(), // Now using the correct one
      },
    );
  }
}
