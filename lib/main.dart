import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Control',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F0F0), // Classic XP gray
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A246A), // XP title bar color
          elevation: 0,
          titleSpacing: 0,
          toolbarHeight: 28, // XP title bar height
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF0F0F0), // XP button face
            foregroundColor: Colors.black,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
              side: const BorderSide(
                color: Color(0xFF808080), // XP button shadow
              ),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
