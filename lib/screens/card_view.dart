import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_application_1/constants.dart';
import '../templates.dart';
import '../widgets/character_card.dart' show CharacterCard, PlacedSticker, TrimmedStickerImage;
import '../widgets/character_template.dart';
import '../utils/export_helper.dart';

class CardView extends StatefulWidget {
  const CardView({super.key});

  @override
  State<CardView> createState() => _CardViewState();
}

class _CardViewState extends State<CardView> {
  int _bgIndex = 0;
  int _tmIndex = 0;
  List<String> _backgrounds = [];
  List<(String, String)> _templates = [];
  Map<String, List<String>> _stickersByCategory = {};
  final List<PlacedSticker> _placedStickers = [];
  bool _showStickerPanel = false;
  bool _isExporting = false;
  FieldMode _globalMode = FieldMode.type;
  Uint8List? _customImageBytes;

  final ValueNotifier<Offset> _rotation = ValueNotifier(Offset.zero);
  final ValueNotifier<UniqueKey?> _selectionNotifier = ValueNotifier(null);
  final GlobalKey _repaintKey = GlobalKey();
  final GlobalKey<CharacterTemplateState> _templateKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    loadBackgrounds().then((b) => setState(() => _backgrounds = b));
    loadAllTemplates().then((t) => setState(() => _templates = t));
    loadStickers().then((s) => setState(() => _stickersByCategory = s));
    _selectionNotifier.addListener(() => setState(() {}));
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    _rotation.dispose();
    _selectionNotifier.dispose();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  // Derived display strings

  String get _currentBgName => _backgrounds.isNotEmpty
      ? _backgrounds[_bgIndex].split('/').last.replaceAll('.png', '').replaceAll('_', ' ')
      : '';
  String get _currentTemplatePath => _templates.isNotEmpty ? _templates[_tmIndex].$2 : '';
  String get _currentCategory     => _templates.isNotEmpty ? _templates[_tmIndex].$1 : '';
  String get _currentTemplateName => _templates.isNotEmpty
      ? _currentTemplatePath.split('/').last.replaceAll('.png', '').replaceAll('_', ' ')
      : '';

  bool get _somethingSelected   => _selectionNotifier.value != null;
  bool get _selectedIsSticker   => _placedStickers.any((s) => s.key == _selectionNotifier.value);
  bool get _selectedIsTextField => _somethingSelected && !_selectedIsSticker;

  String? get _currentFont {
    final key = _selectionNotifier.value;
    if (key == null || _selectedIsSticker) return null;
    return _templateKey.currentState?.getFont(key);
  }

  // Keyboard handler — only intercepts Delete for stickers and for text in move mode,
  // so text fields can still handle their own backspace while editing.
  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final isDelete = event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace;
    if (isDelete && (_selectedIsSticker || _globalMode == FieldMode.move)) {
      _deleteSelected();
      return true;
    }
    return false;
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

  void _onStickerDropped(DragTargetDetails<String> details) {
    final rb = _repaintKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    setState(() => _placedStickers.add(PlacedSticker(details.data, rb.globalToLocal(details.offset))));
  }

  void _resizeSelected(double delta) {
    final key = _selectionNotifier.value;
    if (key == null) return;
    if (_selectedIsSticker) {
      setState(() {
        final s = _placedStickers.firstWhere((s) => s.key == key);
        s.size = (s.size + delta).clamp(20.0, 400.0);
      });
    } else {
      _templateKey.currentState?.resizeField(key, delta);
    }
  }

  void _cycleSelectedFont() {
    final key = _selectionNotifier.value;
    if (key == null) return;
    _templateKey.currentState?.cycleFont(key);
    setState(() {});
  }

  void _deleteSelected() {
    final key = _selectionNotifier.value;
    if (key == null) return;
    _selectionNotifier.value = null;
    if (_placedStickers.any((s) => s.key == key)) {
      setState(() => _placedStickers.removeWhere((s) => s.key == key));
    } else {
      _templateKey.currentState?.deleteField(key);
    }
  }

  Future<void> _exportCard() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isExporting = true);
    await WidgetsBinding.instance.endOfFrame;
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      await saveCardImage(byteData!.buffer.asUint8List());
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Center(child: Image.asset('assets/extras/title.jpg', scale: 1, height: 50)),
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
                  // Card with drag-drop target for stickers
                  if (_templates.isNotEmpty && _backgrounds.isNotEmpty)
                    DragTarget<String>(
                      onAcceptWithDetails: _onStickerDropped,
                      builder: (context, candidateData, _) => AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: candidateData.isNotEmpty
                              ? [const BoxShadow(color: Colors.white38, blurRadius: 16, spreadRadius: 4)]
                              : [],
                        ),
                        child: _HoverCard(
                          rotation: _rotation,
                          backgroundPath: _backgrounds[_bgIndex],
                          templatePath: _currentTemplatePath,
                          customImageBytes: _customImageBytes,
                          repaintKey: _repaintKey,
                          showHandles: !_isExporting,
                          moveMode: _globalMode == FieldMode.move,
                          placedStickers: _placedStickers,
                          selectionNotifier: _selectionNotifier,
                          templateKey: _templateKey,
                          onStickerMoved: (key, pos) => setState(() {
                            _placedStickers.firstWhere((s) => s.key == key).position = pos;
                          }),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Type / Move global toggle
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ModeButton(
                        label: 'Type',
                        icon: Icons.edit,
                        active: _globalMode == FieldMode.type,
                        onTap: () => setState(() => _globalMode = FieldMode.type),
                      ),
                      const SizedBox(width: 8),
                      _ModeButton(
                        label: 'Move',
                        icon: Icons.open_with,
                        active: _globalMode == FieldMode.move,
                        onTap: () => setState(() => _globalMode = FieldMode.move),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Per-item toolbar, visible when something is selected
                  if (_somethingSelected)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: Colors.white),
                                onPressed: () => _resizeSelected(-4),
                              ),
                              Text(
                                _selectedIsSticker ? 'Sticker Size' : 'Text Size',
                                style: const TextStyle(color: Colors.white70, fontFamily: fontBody, fontSize: 18),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.white),
                                onPressed: () => _resizeSelected(4),
                              ),
                            ],
                          ),
                          if (_selectedIsTextField) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Font:', style: TextStyle(color: Colors.white70, fontFamily: fontBody, fontSize: 16)),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _cycleSelectedFont,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white38),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  ),
                                  child: Text(
                                    _currentFont ?? fontBody,
                                    style: TextStyle(fontFamily: _currentFont ?? fontBody, fontSize: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Background picker
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _backgrounds.isEmpty ? null : () => setState(() => _bgIndex = (_bgIndex - 1 + _backgrounds.length) % _backgrounds.length),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Text('Background', style: TextStyle(color: Colors.white, fontFamily: fontBody, fontSize: 40)),
                      IconButton(
                        onPressed: _backgrounds.isEmpty ? null : () => setState(() => _bgIndex = (_bgIndex + 1) % _backgrounds.length),
                        icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      ),
                    ],
                  ),
                  Text(_currentBgName, style: TextStyle(color: Colors.white70, fontFamily: fontBody, fontSize: 20, letterSpacing: 1.5)),

                  // Template picker
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _templates.isEmpty ? null : () => setState(() => _tmIndex = (_tmIndex - 1 + _templates.length) % _templates.length),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Text('Template', style: TextStyle(color: Colors.white, fontFamily: fontBody, fontSize: 40)),
                      IconButton(
                        onPressed: _templates.isEmpty ? null : () => setState(() => _tmIndex = (_tmIndex + 1) % _templates.length),
                        icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      ),
                    ],
                  ),
                  if (_templates.isNotEmpty) ...[
                    Text(_currentCategory, style: TextStyle(color: Colors.white70, fontFamily: fontBody, fontSize: 20, letterSpacing: 1.5)),
                    Text(_currentTemplateName, style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: fontBody)),
                  ],

                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Image', style: TextStyle(color: Colors.black, fontFamily: fontBody, fontSize: 30)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _showStickerPanel = !_showStickerPanel),
                    icon: Icon(_showStickerPanel ? Icons.close : Icons.add_to_photos),
                    label: Text(
                      _showStickerPanel ? 'Close Stickers' : 'Add Sticker',
                      style: const TextStyle(color: Colors.black, fontFamily: fontBody, fontSize: 30),
                    ),
                  ),
                  if (_showStickerPanel) _StickerPanel(stickersByCategory: _stickersByCategory),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportCard,
                    icon: _isExporting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download),
                    label: const Text('Export Image', style: TextStyle(color: Colors.black, fontFamily: fontBody, fontSize: 30)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StickerPanel extends StatelessWidget {
  final Map<String, List<String>> stickersByCategory;
  const _StickerPanel({required this.stickersByCategory});

  @override
  Widget build(BuildContext context) {
    if (stickersByCategory.isEmpty) {
      return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in stickersByCategory.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                entry.key,
                style: const TextStyle(color: Colors.white70, fontFamily: fontBody, fontSize: 18, letterSpacing: 1.2),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final path in entry.value)
                  Draggable<String>(
                    data: path,
                    feedback: Opacity(opacity: 0.85, child: TrimmedStickerImage(assetPath: path, size: 150)),
                    childWhenDragging: Opacity(opacity: 0.3, child: TrimmedStickerImage(assetPath: path, size: 150)),
                    child: Tooltip(
                      message: path.split('/').last.replaceAll('.png', '').replaceAll('_', ' '),
                      child: TrimmedStickerImage(assetPath: path, size: 150),
                    ),
                  ),
              ],
            ),
          ],
        ],
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
  final bool moveMode;
  final List<PlacedSticker> placedStickers;
  final ValueNotifier<UniqueKey?> selectionNotifier;
  final GlobalKey<CharacterTemplateState> templateKey;
  final void Function(UniqueKey key, Offset newPos) onStickerMoved;

  const _HoverCard({
    required this.rotation,
    required this.backgroundPath,
    required this.templatePath,
    this.customImageBytes,
    required this.repaintKey,
    required this.showHandles,
    required this.moveMode,
    required this.placedStickers,
    required this.selectionNotifier,
    required this.templateKey,
    required this.onStickerMoved,
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
      child: RepaintBoundary(
        key: repaintKey,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CharacterCard(
            backgroundPath: backgroundPath,
            templatePath: templatePath,
            customImageBytes: customImageBytes,
            showHandles: showHandles,
            moveMode: moveMode,
            placedStickers: placedStickers,
            selectionNotifier: selectionNotifier,
            templateKey: templateKey,
            onStickerMoved: onStickerMoved,
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ModeButton({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white24 : Colors.white10,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? Colors.white54 : Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontFamily: fontBody, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
