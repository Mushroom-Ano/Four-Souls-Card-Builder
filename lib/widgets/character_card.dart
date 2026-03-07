import 'dart:math' show cos, sin, max;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './character_template.dart';
import './card_item_handle.dart';

class PlacedSticker {
  final UniqueKey key;
  final String assetPath;
  final Uint8List? imageBytes;
  Offset position;
  double size;
  double rotation;
  PlacedSticker(this.assetPath, this.position) : key = UniqueKey(), size = 210, imageBytes = null, rotation = 0;
  PlacedSticker.custom(this.imageBytes, this.position) : key = UniqueKey(), size = 210, assetPath = '', rotation = 0;
}

class CharacterCard extends StatelessWidget {
  final String backgroundPath;
  final String templatePath;
  final Uint8List? customImageBytes;
  final bool showHandles;
  final bool moveMode;
  final List<PlacedSticker> placedStickers;
  final ValueNotifier<UniqueKey?> selectionNotifier;
  final GlobalKey<CharacterTemplateState> templateKey;
  final void Function(UniqueKey key, Offset newPos) onStickerMoved;

  const CharacterCard({
    super.key,
    required this.backgroundPath,
    required this.templatePath,
    this.customImageBytes,
    this.showHandles = true,
    this.moveMode = false,
    required this.placedStickers,
    required this.selectionNotifier,
    required this.templateKey,
    required this.onStickerMoved,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 308,
      height: 400,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(child: Image.asset(backgroundPath, fit: BoxFit.fill)),
          Positioned.fill(
            child: customImageBytes != null
                ? Image.memory(customImageBytes!, fit: BoxFit.cover)
                : Image.asset('assets/cards/images/image.png', fit: BoxFit.cover),
          ),
          Positioned.fill(child: Image.asset(templatePath, fit: BoxFit.fill)),
          CharacterTemplate(
            key: templateKey,
            showHandles: showHandles,
            moveMode: moveMode,
            selectionNotifier: selectionNotifier,
          ),
          for (final sticker in placedStickers)
            Positioned(
              left: sticker.position.dx - sticker.size / 2,
              top: sticker.position.dy - sticker.size / 2,
              child: Transform.rotate(
                angle: sticker.rotation,
                child: CardItemHandle(
                itemKey: sticker.key,
                selectionNotifier: selectionNotifier,
                showHandles: showHandles,
                fullDrag: true,
                onMoved: (delta) => onStickerMoved(sticker.key, sticker.position + _toCardSpace(delta, sticker.rotation)),
                child: sticker.imageBytes != null
                    ? SizedBox(
                        width: sticker.size,
                        height: sticker.size,
                        child: Image.memory(sticker.imageBytes!, fit: BoxFit.contain),
                      )
                    : TrimmedStickerImage(
                        assetPath: sticker.assetPath,
                        size: sticker.size,
                      ),
              ),
              ),
            ),
        ],
      ),
    );
  }
}

Offset _toCardSpace(Offset delta, double angle) {
  if (angle == 0) return delta;
  final c = cos(angle);
  final s = sin(angle);
  return Offset(delta.dx * c - delta.dy * s, delta.dx * s + delta.dy * c);
}

// Cache of trim results keyed by asset path so each image is decoded once.
final _trimCache = <String, Future<_TrimRect>>{};

class _TrimRect {
  final double imgW, imgH;
  final Rect trim;
  const _TrimRect(this.imgW, this.imgH, this.trim);
}

Future<_TrimRect> _loadTrim(String assetPath) {
  return _trimCache.putIfAbsent(assetPath, () async {
    final data = await rootBundle.load(assetPath);

    // Decode at 64 px wide — ~100× fewer pixels to scan, same fractions.
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 64,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final w = image.width;
    final h = image.height;

    final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (pixels == null) {
      return _TrimRect(w.toDouble(), h.toDouble(),
          Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
    }

    int alpha(int x, int y) => pixels.getUint8((y * w + x) * 4 + 3);

    // Scan inward from each edge to find the non-transparent bounding box.
    int minY = 0;
    outer1: for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) { if (alpha(x, y) > 10) { minY = y; break outer1; } }
    }
    int maxY = h - 1;
    outer2: for (int y = h - 1; y >= minY; y--) {
      for (int x = 0; x < w; x++) { if (alpha(x, y) > 10) { maxY = y; break outer2; } }
    }
    int minX = 0;
    outer3: for (int x = 0; x < w; x++) {
      for (int y = minY; y <= maxY; y++) { if (alpha(x, y) > 10) { minX = x; break outer3; } }
    }
    int maxX = w - 1;
    outer4: for (int x = w - 1; x >= minX; x--) {
      for (int y = minY; y <= maxY; y++) { if (alpha(x, y) > 10) { maxX = x; break outer4; } }
    }

    return _TrimRect(
      w.toDouble(), h.toDouble(),
      Rect.fromLTRB(minX.toDouble(), minY.toDouble(),
          (maxX + 1).toDouble(), (maxY + 1).toDouble()),
    );
  });
}

class TrimmedStickerImage extends StatefulWidget {
  final String assetPath;
  final double size;

  const TrimmedStickerImage({required this.assetPath, required this.size});

  @override
  State<TrimmedStickerImage> createState() => _TrimmedStickerImageState();
}

class _TrimmedStickerImageState extends State<TrimmedStickerImage> {
  late Future<_TrimRect> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadTrim(widget.assetPath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TrimRect>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Image.asset(widget.assetPath, width: widget.size, height: widget.size);
        }

        final t = snapshot.data!;
        final scale = widget.size / max(t.trim.width, t.trim.height);
        final dispW = t.trim.width * scale;
        final dispH = t.trim.height * scale;
        final fullW = t.imgW * scale;
        final fullH = t.imgH * scale;

        // Shift the full image left/up so the content lands at (0, 0),
        // then clip to the content size. Stack lets Positioned children
        // render larger than the stack, so the image isn't clamped.
        return SizedBox(
          width: dispW,
          height: dispH,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -t.trim.left * scale,
                top:  -t.trim.top  * scale,
                child: Image.asset(
                  widget.assetPath,
                  width: fullW,
                  height: fullH,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
