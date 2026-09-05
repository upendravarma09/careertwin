import 'package:flutter/material.dart';
import 'profile_screen.dart';

void main() {
  runApp(const CareerTwinApp());
}

class CareerTwinApp extends StatelessWidget {
  const CareerTwinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareerTwin AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        useMaterial3: true,
      ),
      home: const ProfileScreen(),
    );
  }
}