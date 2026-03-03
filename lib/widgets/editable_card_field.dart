import 'package:flutter/material.dart';

class EditableCardField extends StatefulWidget {
  final String initialText;
  final String fontType;
  final double fontSize;
  final Color fontColor;
  final double fontHeight;
  final int? maxLines;
  final TextAlign textAlign;
  final double? width;
  final VoidCallback? onDelete;
  final bool autofocus;

  const EditableCardField({
    super.key,
    required this.initialText,
    required this.fontType,
    required this.fontSize,
    required this.fontColor,
    required this.fontHeight,
    this.maxLines,
    this.textAlign = TextAlign.center,
    this.width,
    this.onDelete,
    this.autofocus = false,
  });

  @override
  State<EditableCardField> createState() => _EditableCardFieldState();
}

class _EditableCardFieldState extends State<EditableCardField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(() => setState(() {}));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _controller.text.isEmpty) {
        widget.onDelete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: widget.fontType,
      fontSize: widget.fontSize,
      height: widget.fontHeight,
      color: widget.fontColor,
    );

    Widget child = TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      textAlign: widget.textAlign,
      style: style,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
      ),
    );

    if (widget.width != null) {
      final width = widget.width! + _controller.text.length * 20.0;
      return SizedBox(width: width, child: child);
    }
    return child;
  }
}
