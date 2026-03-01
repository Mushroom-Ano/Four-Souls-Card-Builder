import 'package:flutter/material.dart';

const fontTitle = 'Title';
const fontBody = 'Body';
const kTextColor = Color(0xFF30221D);

void main() => runApp(const FourSoulsCardApp());

class FourSoulsCardApp extends StatelessWidget {
  const FourSoulsCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CardView(),
    );
  }
}

class CardView extends StatefulWidget {
  const CardView({super.key});

  @override
  State<CardView> createState() => _CardViewState();
}

class _CardViewState extends State<CardView> {
  Offset _rotation = Offset.zero;

  void _onHover(PointerEvent event) {
    final size = MediaQuery.of(context).size;
    final dx = (event.localPosition.dx / size.width - 0.5) * 2;
    final dy = (event.localPosition.dy / size.height - 0.5) * 2;
    setState(() {
      _rotation = Offset(dx * 0.4, dy * 0.4);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MouseRegion(
        onHover: _onHover,
        child: Center(
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_rotation.dy)
              ..rotateY(_rotation.dx),
            alignment: FractionalOffset.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CharacterCard(

              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CharacterCard extends StatelessWidget {
  const CharacterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 308,
      height: 400,
      child: Stack(
        
        children: [
          // card background image
          Positioned.fill(

            child: Image.asset(
              'assets/cards/blank-character.png',
              fit: BoxFit.fill,
              
              

            ),
            
          ),
          // title 
          Positioned(
            top: 24,
            left: 40,
            right: 40,
            child: EditableCardField(
              initialText: 'ISAAC',
              fontType: fontTitle,
              fontSize: 25,
              fontHeight: 0,
              fontColor: Colors.black,
              textAlign: TextAlign.center,
            ),
          ),
          // HP value 
          Positioned(
            top: 235,
            left: 120,
            child: EditableCardField(
              initialText: '2',
              fontType: fontTitle,
              fontSize: 25,
              fontHeight: 0,
              fontColor: Colors.black,
              width: 30,
            ),
          ),
          // ATK value 
          Positioned(
            top: 235,
            left: 185,
            child: EditableCardField(
              initialText: '1',
              fontType: fontTitle,
              fontSize: 25,
              fontHeight: 0,
              fontColor: Colors.black,
              width: 30,
            ),
          ),
          // description 
          Positioned(
            bottom: 100,
            left: 60,
            right: 30,
            child: EditableCardField(
              initialText: 'PLAY AN ADDITIONAL LOOT CARD THIS TURN.',
              fontType: fontBody,
              fontSize: 20,
              fontHeight: 0.7,
              fontColor: Colors.black,
              maxLines: 2,
              width: 0,
            ),
          ),
          // the grey desc
          Positioned(
            bottom: 75,
            left: 30,
            right: 30,
            child: EditableCardField(
              initialText: "THIS CAN BE DONE ON ANY PLAYER'S TURN IN RESPONSE TO ANY ACTION.",
              fontType: fontBody,
              fontSize: 16,
              fontHeight: 0.7,
              fontColor: Colors.grey,
              maxLines: 3,
              width: 0,
            ),
          ),
          // bottom description
          Positioned(
            bottom: 35,
            left: 80,
            right: 80,
            child: EditableCardField(
              initialText: 'STARTING ITEM: THE D6',
              fontType: fontBody,
              fontSize: 20,
              fontHeight: 0.7,
              fontColor: Colors.black,
              maxLines: 2,
              width: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class EditableCardField extends StatefulWidget {
  final String initialText;
  final String fontType;
  final double fontSize;
  final Color fontColor;
  final double fontHeight;
  final int maxLines;
  final TextAlign textAlign;
  final double? width;

  const EditableCardField({
    super.key,
    required this.initialText,
    required this.fontType,
    required this.fontSize,
    required this.fontColor,
    required this.fontHeight,
    this.maxLines = 1,
    this.textAlign = TextAlign.center,
    this.width,
  });

  @override
  State<EditableCardField> createState() => _EditableCardFieldState();
}

class _EditableCardFieldState extends State<EditableCardField> {
  late String _text;
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _text = widget.initialText;
    _controller = TextEditingController(text: _text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    setState(() {
      _text = _controller.text.isEmpty ? widget.initialText : _controller.text;
      _editing = false;
    });
  }
  

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: widget.fontType,
      fontSize: widget.fontSize,
      height: widget.fontHeight,
      color: widget.fontColor,
    );

    Widget child;
    if (_editing) {
      child = TextField(
        controller: _controller,
        autofocus: true,
        maxLines: widget.maxLines,
        textAlign: widget.textAlign,
        style: style,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
        ),
        onSubmitted: widget.maxLines == 1 ? (_) => _save() : null,
        onTapOutside: (_) => _save(),
      );
    } else {
      child = GestureDetector(
        onTap: () {
          _controller.text = _text;
          setState(() => _editing = true);
        },
        child: Text(
          _text,
          textAlign: widget.textAlign,
          maxLines: widget.maxLines,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      );
    }

    if (widget.width != null) {
      return SizedBox(width: widget.width, child: child);
    }
    return child;
  }
}
