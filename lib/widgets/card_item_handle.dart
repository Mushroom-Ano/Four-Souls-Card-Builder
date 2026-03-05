import 'package:flutter/material.dart';

// Wraps a card item (text field or sticker) with tap-to-select and drag.
//
// fullDrag = true  → the whole area drags when selected (stickers).
// fullDrag = false → only 10 px edge strips drag (text in type mode).
class CardItemHandle extends StatelessWidget {
  final UniqueKey itemKey;
  final ValueNotifier<UniqueKey?> selectionNotifier;
  final bool showHandles;
  final bool fullDrag;
  final void Function(Offset delta) onMoved;
  final Widget child;

  const CardItemHandle({
    super.key,
    required this.itemKey,
    required this.selectionNotifier,
    required this.showHandles,
    required this.fullDrag,
    required this.onMoved,
    required this.child,
  });

  static const _edgeWidth = 10.0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UniqueKey?>(
      valueListenable: selectionNotifier,
      builder: (context, selectedKey, _) {
        final isSelected = showHandles && selectedKey == itemKey;

        final decorated = DecoratedBox(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Colors.blue.withValues(alpha: 0.75), width: 2)
                : null,
          ),
          child: child,
        );

        if (fullDrag) {
          return GestureDetector(
            behavior: isSelected
                ? HitTestBehavior.opaque
                : HitTestBehavior.translucent,
            onTap: showHandles
                ? () => selectionNotifier.value = isSelected ? null : itemKey
                : null,
            onPanUpdate: isSelected ? (d) => onMoved(d.delta) : null,
            child: MouseRegion(
              cursor: isSelected && showHandles
                  ? SystemMouseCursors.move
                  : MouseCursor.defer,
              child: decorated,
            ),
          );
        }

        // Edge-strip mode: tap selects/deselects, thin borders handle drag.
        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: showHandles
                  ? () => selectionNotifier.value = isSelected ? null : itemKey
                  : null,
              child: decorated,
            ),
            if (isSelected) ...[
              Positioned(
                left: 0, right: 0, top: 0,
                child: _EdgeStrip(height: _edgeWidth, onMoved: onMoved),
              ),
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: _EdgeStrip(height: _edgeWidth, onMoved: onMoved),
              ),
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: _EdgeStrip(width: _edgeWidth, onMoved: onMoved),
              ),
              Positioned(
                right: 0, top: 0, bottom: 0,
                child: _EdgeStrip(width: _edgeWidth, onMoved: onMoved),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _EdgeStrip extends StatelessWidget {
  final void Function(Offset delta) onMoved;
  final double? width;
  final double? height;

  const _EdgeStrip({required this.onMoved, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) => onMoved(d.delta),
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        child: SizedBox(width: width, height: height),
      ),
    );
  }
}
