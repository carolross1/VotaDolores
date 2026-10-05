import 'package:flutter/material.dart';
import 'presentation/votacion_screen.dart';

void main() => runApp(const VotaDoloresApp());

class VotaDoloresApp extends StatelessWidget {
  const VotaDoloresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vota Dolores Hidalgo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF283593)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const VotacionScreen(),
    );
  }
}
