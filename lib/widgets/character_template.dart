import 'package:flutter/material.dart';
import '../constants.dart';
import 'editable_card_field.dart';

class CharacterTemplate extends StatefulWidget {
  const CharacterTemplate({super.key});

  @override
  State<CharacterTemplate> createState() => _CharacterTemplateState();
}

class _FieldEntry {
  final UniqueKey key;
  Offset position;
  _FieldEntry(this.position) : key = UniqueKey();
}

class _CharacterTemplateState extends State<CharacterTemplate> {
  final List<_FieldEntry> _fields = [];

  void _addField(TapUpDetails details) {
    setState(() {
      _fields.add(_FieldEntry(details.localPosition));
    });
  }

  void _removeField(UniqueKey key) {
    setState(() {
      _fields.removeWhere((f) => f.key == key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: _addField,
          ),
        ),
        for (final f in _fields) ...[
          Positioned(
            left: f.position.dx - 18,
            top: f.position.dy,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) => setState(() => f.position += d.delta),
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: Colors.grey.withOpacity(0.6),
                ),
              ),
            ),
          ),
          // Text field
          Positioned(
            key: f.key,
            left: f.position.dx,
            top: f.position.dy,
            child: EditableCardField(
              initialText: '',
              fontType: fontBody,
              fontSize: 25,
              fontHeight: 0,
              fontColor: Colors.black,
              textAlign: TextAlign.left,
              autofocus: true,
              width: 30,
              onDelete: () => _removeField(f.key),
            ),
          ),
        ],
      ],
    );
  }
}
