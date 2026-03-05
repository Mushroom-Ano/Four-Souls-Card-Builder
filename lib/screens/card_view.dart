import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_application_1/constants.dart';
import '../templates.dart';
import '../widgets/character_card.dart';
import '../utils/export_helper.dart';

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
  final GlobalKey _repaintKey = GlobalKey();
  bool _isExporting = false;

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

  Future<void> _exportCard() async {
    // Unfocus any active text field so the cursor doesn't appear in the export
    FocusManager.instance.primaryFocus?.unfocus();

    // Hide drag handles and wait for the frame to render without them
    setState(() => _isExporting = true);
    await WidgetsBinding.instance.endOfFrame;

    try {
      final boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      await saveCardImage(pngBytes);
    } finally {
      setState(() => _isExporting = false);
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
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - kToolbarHeight),
            child: Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HoverCard(
                rotation: _rotation,
                backgroundPath: _backgrounds[_bgIndex],
                templatePath: characterTemplates[_tmIndex],
                customImageBytes: _customImageBytes,
                repaintKey: _repaintKey,
                showHandles: !_isExporting,
              ),
              const SizedBox(height: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Background switcher
                  Text(
                      "Background",
                      style:TextStyle(
                        color: Colors.white,
                        fontFamily: fontBody,
                        fontSize: 40,
                      )
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    IconButton(
                      onPressed: () => setState(() => _bgIndex = (_bgIndex - 1 + _backgrounds.length) % _backgrounds.length),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text(_bgIndex.toString(), style: const TextStyle(color: Colors.white, fontSize: 32, fontFamily: fontBody)),
                    IconButton(
                      onPressed: () => setState(() => _bgIndex = (_bgIndex + 1) % _backgrounds.length),
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ]),
                  // Template switcher
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
                icon: const Icon(Icons.add_to_photos),
                label: const Text(
                    "Add Sticker",
                    style:TextStyle(
                      color: Colors.black,
                      fontFamily: fontBody,
                      fontSize: 30,
                    )
                  ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportCard,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: const Text(
                  "Export Image",
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: fontBody,
                    fontSize: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
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
  final GlobalKey repaintKey;
  final bool showHandles;

  const _HoverCard({
    required this.rotation,
    required this.backgroundPath,
    required this.templatePath,
    this.customImageBytes,
    required this.repaintKey,
    required this.showHandles,
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
      // RepaintBoundary is inside the Transform so the capture is always flat
      child: RepaintBoundary(
        key: repaintKey,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CharacterCard(
            backgroundPath: backgroundPath,
            templatePath: templatePath,
            customImageBytes: customImageBytes,
            showHandles: showHandles,
          ),
        ),
      ),
    );
  }
}
