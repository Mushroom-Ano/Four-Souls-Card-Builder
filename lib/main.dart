import 'package:flutter/material.dart';
import 'screens/card_view.dart';

void main() => runApp(const FourSoulsCardApp());

class FourSoulsCardApp extends StatelessWidget {
  const FourSoulsCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CardView(),
    );
  }
}
