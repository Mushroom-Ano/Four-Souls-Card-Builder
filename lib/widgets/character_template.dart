import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants.dart';

enum FieldMode { type, move }

const _availableFonts = [fontBody, fontTitle];

class _FieldEntry {
  final UniqueKey key;
  Offset position;
  double fontSize;
  String font;
  String text;

  _FieldEntry(this.position)
      : key = UniqueKey(),
        fontSize = 22,
        font = fontBody,
        text = '';
}

class CharacterTemplate extends StatefulWidget {
  final bool showHandles;
  final bool moveMode;
  final ValueNotifier<UniqueKey?> selectionNotifier;

  const CharacterTemplate({
    super.key,
    this.showHandles = true,
    required this.moveMode,
    required this.selectionNotifier,
  });

  @override
  CharacterTemplateState createState() => CharacterTemplateState();
}

class CharacterTemplateState extends State<CharacterTemplate> {
  final List<_FieldEntry> _fields = [];
  UniqueKey? _editingKey;

  @override
  void didUpdateWidget(CharacterTemplate old) {
    super.didUpdateWidget(old);
    // Drop editing when the user switches to move mode.
    if (widget.moveMode && !old.moveMode && _editingKey != null) {
      setState(() => _editingKey = null);
    }
  }

  void _onCardTapped(TapUpDetails details) {
    if (widget.moveMode) return;
    final entry = _FieldEntry(details.localPosition);
    setState(() {
      _fields.add(entry);
      _editingKey = entry.key;
    });
    widget.selectionNotifier.value = entry.key;
  }

  void _onTextTapped(UniqueKey key) {
    widget.selectionNotifier.value = key;
    if (!widget.moveMode) setState(() => _editingKey = key);
  }

  void _onEditUnfocus(UniqueKey key) {
    final idx = _fields.indexWhere((f) => f.key == key);
    if (idx == -1) return;
    setState(() {
      _editingKey = null;
      if (_fields[idx].text.isEmpty) {
        _fields.removeAt(idx);
        if (widget.selectionNotifier.value == key) widget.selectionNotifier.value = null;
      }
    });
  }

  // Public API called via GlobalKey from card_view.

  void deleteField(UniqueKey key) {
    setState(() {
      _fields.removeWhere((f) => f.key == key);
      if (_editingKey == key) _editingKey = null;
    });
  }

  void resizeField(UniqueKey key, double delta) {
    final idx = _fields.indexWhere((f) => f.key == key);
    if (idx == -1) return;
    setState(() => _fields[idx].fontSize = (_fields[idx].fontSize + delta).clamp(8.0, 80.0));
  }

  void cycleFont(UniqueKey key) {
    final idx = _fields.indexWhere((f) => f.key == key);
    if (idx == -1) return;
    setState(() {
      final next = (_availableFonts.indexOf(_fields[idx].font) + 1) % _availableFonts.length;
      _fields[idx].font = _availableFonts[next];
    });
  }

  String? getFont(UniqueKey key) {
    final idx = _fields.indexWhere((f) => f.key == key);
    return idx != -1 ? _fields[idx].font : null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tap anywhere on the card to add a new text field.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: _onCardTapped,
          ),
        ),

        for (final f in _fields)
          if (!widget.moveMode && _editingKey == f.key)
            Positioned(
              left: f.position.dx,
              top: f.position.dy,
              child: _EditingTextField(
                key: f.key,
                entry: f,
                onTextChanged: (v) => f.text = v,
                onUnfocus: () => _onEditUnfocus(f.key),
                onMoved: (delta) => setState(() => f.position += delta),
              ),
            )
          else if (f.text.isNotEmpty)
            Positioned(
              left: f.position.dx,
              top: f.position.dy,
              child: _DraggableText(
                key: f.key,
                entry: f,
                showHandles: widget.showHandles,
                selectionNotifier: widget.selectionNotifier,
                onTap: () => _onTextTapped(f.key),
                onMoved: (delta) => setState(() => f.position += delta),
              ),
            ),
      ],
    );
  }
}

class _EditingTextField extends StatefulWidget {
  final _FieldEntry entry;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onUnfocus;
  final ValueChanged<Offset> onMoved;

  const _EditingTextField({
    required super.key,
    required this.entry,
    required this.onTextChanged,
    required this.onUnfocus,
    required this.onMoved,
  });

  @override
  State<_EditingTextField> createState() => _EditingTextFieldState();
}

class _EditingTextFieldState extends State<_EditingTextField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry.text);
    _controller.addListener(() => setState(() {}));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) widget.onUnfocus();
    });
    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          final sel = _controller.selection;
          final text = _controller.text;
          final newText = text.replaceRange(sel.start, sel.end, '\n');
          _controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: sel.start + 1),
          );
          widget.onTextChanged(newText);
          return KeyEventResult.handled;
        } else {
          _focusNode.unfocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = _controller.text.split('\n');
    final maxLen = lines.fold(0, (m, l) => l.length > m ? l.length : m);
    final width = 30.0 + maxLen * widget.entry.fontSize * 0.6;
    return SizedBox(
      width: width,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        maxLines: null,
        onChanged: widget.onTextChanged,
        style: TextStyle(
          fontFamily: widget.entry.font,
          fontSize: widget.entry.fontSize,
          color: Colors.black,
          height: 1.1,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// Frozen text shown when a field is unfocused. Always draggable.
class _DraggableText extends StatelessWidget {
  final _FieldEntry entry;
  final bool showHandles;
  final ValueNotifier<UniqueKey?> selectionNotifier;
  final VoidCallback onTap;
  final ValueChanged<Offset> onMoved;

  const _DraggableText({
    required super.key,
    required this.entry,
    required this.showHandles,
    required this.selectionNotifier,
    required this.onTap,
    required this.onMoved,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UniqueKey?>(
      valueListenable: selectionNotifier,
      builder: (context, selectedKey, _) {
        final isSelected = showHandles && selectedKey == entry.key;
        return GestureDetector(
          onTap: onTap,
          onPanUpdate: (d) => onMoved(d.delta),
          child: MouseRegion(
            cursor: SystemMouseCursors.move,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: Colors.blue.withValues(alpha: 0.75), width: 2)
                    : null,
              ),
              child: Text(
                entry.text,
                style: TextStyle(
                  fontFamily: entry.font,
                  fontSize: entry.fontSize,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
