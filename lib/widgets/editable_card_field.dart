import 'package:flutter/material.dart';

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
