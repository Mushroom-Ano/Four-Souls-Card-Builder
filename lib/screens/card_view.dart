import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  Offset _rotation = Offset.zero;
  int _bgIndex = 0;
  int _tmIndex = 0;
  Uint8List? _customImageBytes;

  void _onHover(PointerEvent event) {
    final size = MediaQuery.of(context).size;
    final dx = (event.localPosition.dx / size.width - 0.5) * 2;
    final dy = (event.localPosition.dy / size.height - 0.5) * 2;
    setState(() {
      _rotation = Offset(dx * 0.4, dy * 0.4);
    });
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
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_rotation.dy)
                  ..rotateY(_rotation.dx),
                alignment: FractionalOffset.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CharacterCard(
                    backgroundPath: _backgrounds[_bgIndex],
                    templatePath: characterTemplates[_tmIndex],
                    customImageBytes: _customImageBytes,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Background switcher
                  IconButton(
                    onPressed: () => setState(() => _bgIndex = (_bgIndex - 1 + _backgrounds.length) % _backgrounds.length),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Text(_bgIndex.toString(), style: const TextStyle(color: Colors.white, fontSize: 16)),
                  IconButton(
                    onPressed: () => setState(() => _bgIndex = (_bgIndex + 1) % _backgrounds.length),
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                  // Template switcher
                  IconButton(
                    onPressed: () => setState(() => _tmIndex = (_tmIndex - 1 + characterTemplates.length) % characterTemplates.length),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Text(_tmIndex.toString(), style: const TextStyle(color: Colors.white, fontSize: 16)),
                  IconButton(
                    onPressed: () => setState(() => _tmIndex = (_tmIndex + 1) % characterTemplates.length),
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Image'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickImage,
                label: const Text('Add Sticker'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
