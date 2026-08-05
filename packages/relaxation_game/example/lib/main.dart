import 'package:flutter/material.dart';
import 'package:relaxation_game/relaxation_game.dart';

void main() => runApp(const RelaxationGameExample());

class RelaxationGameExample extends StatelessWidget {
  const RelaxationGameExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '동물 팡팡',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF66B5F8)),
        useMaterial3: true,
      ),
      home: const AnimalMatchGamePage(),
    );
  }
}
