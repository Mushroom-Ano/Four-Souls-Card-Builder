import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_application_1/constants.dart';
import '../templates.dart';
import '../widgets/character_card.dart';

const _backgrounds = [
  'assets/cards/backgrounds/Background_Basement.png',
  'assets/cards/backgrounds/Background_Depths.png',
  'assets/cards/backgrounds/Background_Downpour.png',
  'assets/cards/backgrounds/Background_Dross.png',
  'assets/cards/backgrounds/Background_Steven.png',
  'assets/cards/backgrounds/Character_Realistic_DarkSiders.png',
  'assets/cards/backgrounds/Cus_Antibirth_Mitboy.png',
  'assets/cards/backgrounds/Cus_Library_Mitboy.png',

];

const _bgNames = ['Default', 'Arcade', 'Mines', 'Tainted'];

class CardView extends StatefulWidget {
  const CardView({super.key});

  @override
  State<CardView> createState() => _CardViewState();
}

class _CardViewState extends State<CardView> {
  int _bgIndex = 0;
  int _tmIndex = 0;
  Uint8List? _customImageBytes;
  final ValueNotifier<Offset> _rotation = ValueNotifier(Offset.zero);

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent event) {
    final size = MediaQuery.of(context).size;
    final dx = (event.localPosition.dx / size.width - 0.5) * 2;
    final dy = (event.localPosition.dy / size.height - 0.5) * 2;
    _rotation.value = Offset(dx * 0.4, dy * 0.4);
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() => _customImageBytes = result.files.single.bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Center(
          child: Image.asset(
            'assets/extras/title.jpg',
            scale: 1,
            height: 50,
          ),
        ),
      ),
      backgroundColor: Colors.black,
      body: MouseRegion(
        onHover: _onHover,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HoverCard(
                rotation: _rotation,
                backgroundPath: _backgrounds[_bgIndex],
                templatePath: characterTemplates[_tmIndex],
                customImageBytes: _customImageBytes,
              ),
              const SizedBox(height: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Background switcher
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    IconButton(
                      onPressed: () => setState(() => _bgIndex = (_bgIndex - 1 + _backgrounds.length) % _backgrounds.length),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text(
                      "Background",
                      style:TextStyle(
                        color: Colors.white,
                        fontFamily: fontBody,
                        fontSize: 40,
                      )
                    ),
                    IconButton(
                      onPressed: () => setState(() => _bgIndex = (_bgIndex + 1) % _backgrounds.length),
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ]),
                  //Background Index
                  Text(_bgIndex.toString(), style: const TextStyle(color: Colors.white, fontSize: 32, fontFamily: fontBody)),
                  // Background switcher
                  Text(
                    "Template",
                    style:TextStyle(
                      color: Colors.white,
                      fontFamily: fontBody,
                      fontSize: 40,
                    )
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Template switcher
                      IconButton(
                        onPressed: () => setState(() => _tmIndex = (_tmIndex - 1 + characterTemplates.length) % characterTemplates.length),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Text(_tmIndex.toString(), style: const TextStyle(color: Colors.white, fontSize: 32, fontFamily: fontBody)),
                      IconButton(
                        onPressed: () => setState(() => _tmIndex = (_tmIndex + 1) % characterTemplates.length),
                        icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file),
                label: const Text(
                    "Upload Image",
                    style:TextStyle(
                      color: Colors.black,
                      fontFamily: fontBody,
                      fontSize: 30,
                    )
                  ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickImage,
                label: const Text(
                    "Add Sticker",
                    style:TextStyle(
                      color: Colors.black,
                      fontFamily: fontBody,
                      fontSize: 30,
                    )
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverCard extends StatelessWidget {
  final ValueNotifier<Offset> rotation;
  final String backgroundPath;
  final String templatePath;
  final Uint8List? customImageBytes;

  const _HoverCard({
    required this.rotation,
    required this.backgroundPath,
    required this.templatePath,
    this.customImageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: rotation,
      builder: (context, rot, child) => Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(rot.dy)
          ..rotateY(rot.dx),
        alignment: FractionalOffset.center,
        child: child,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CharacterCard(
          backgroundPath: backgroundPath,
          templatePath: templatePath,
          customImageBytes: customImageBytes,
        ),
      ),
    );
  }
}
