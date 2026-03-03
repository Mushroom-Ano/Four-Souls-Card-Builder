import 'dart:typed_data';
import 'package:flutter/material.dart';
import './character_template.dart';

class CharacterCard extends StatelessWidget {
  final String backgroundPath;
  final String templatePath;
  final Uint8List? customImageBytes;

  const CharacterCard({
    super.key,
    required this.backgroundPath,
    required this.templatePath,
    this.customImageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 308,
      height: 400,
      child: Stack(
        children: [
          // Layer 1: Background
          Positioned.fill(
            child: Image.asset(backgroundPath, fit: BoxFit.fill),
          ),
          // Layer 2: Custom character image (placeholder until uploaded)
          Positioned.fill(
            child: customImageBytes != null
                ? Image.memory(customImageBytes!, fit: BoxFit.cover)
                : Image.asset('assets/cards/images/image.png', fit: BoxFit.cover),
          ),
          // Layer 3: Template overlay
          Positioned.fill(
            child: Image.asset(templatePath, fit: BoxFit.fill),
          ),
          //Stats and stuff.
          CharacterTemplate(),
        ],
      ),
    );
  }
}