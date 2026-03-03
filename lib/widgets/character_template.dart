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
  final Offset position;
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
        ..._fields.map((f) => Positioned(
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
        )),
      ],
    );
  }
}


// Positioned(
        //       top: 24,
        //       left: 40,
        //       right: 40,
        //       child: EditableCardField(
        //         initialText: 'ISAAC',
        //         fontType: fontTitle,
        //         fontSize: 25,
        //         fontHeight: 0,
        //         fontColor: Colors.black,
        //         textAlign: TextAlign.center,
        //       ),
        //     ),
        //     // HP value
        //     Positioned(
        //       top: 235,
        //       left: 120,
        //       child: EditableCardField(
        //         initialText: '2',
        //         fontType: fontTitle,
        //         fontSize: 25,
        //         fontHeight: 0,
        //         fontColor: Colors.black,
        //         width: 30,
        //       ),
        //     ),
        //     // ATK value
        //     Positioned(
        //       top: 235,
        //       left: 185,
        //       child: EditableCardField(
        //         initialText: '1',
        //         fontType: fontTitle,
        //         fontSize: 25,
        //         fontHeight: 0,
        //         fontColor: Colors.black,
        //         width: 30,
        //       ),
        //     ),
        //     // description
        //     Positioned(
        //       bottom: 100,
        //       left: 60,
        //       right: 30,
        //       child: EditableCardField(
        //         initialText: 'PLAY AN ADDITIONAL LOOT CARD THIS TURN.',
        //         fontType: fontBody,
        //         fontSize: 20,
        //         fontHeight: 0.7,
        //         fontColor: Colors.black,
        //         maxLines: 2,
        //         width: 0,
        //       ),
        //     ),
        //     // the grey desc
        //     Positioned(
        //       bottom: 75,
        //       left: 30,
        //       right: 30,
        //       child: EditableCardField(
        //         initialText: "THIS CAN BE DONE ON ANY PLAYER'S TURN IN RESPONSE TO ANY ACTION.",
        //         fontType: fontBody,
        //         fontSize: 16,
        //         fontHeight: 0.7,
        //         fontColor: Colors.grey,
        //         maxLines: 3,
        //         width: 0,
        //       ),
        //     ),
        //     // bottom description
        //     Positioned(
        //       bottom: 35,
        //       left: 80,
        //       right: 80,
        //       child: EditableCardField(
        //         initialText: 'STARTING ITEM: THE D6',
        //         fontType: fontBody,
        //         fontSize: 20,
        //         fontHeight: 0.7,
        //         fontColor: Colors.black,
        //         maxLines: 2,
        //         width: 0,
        //       ),
        //     ),
