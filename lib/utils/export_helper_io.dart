import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<void> saveCardImage(Uint8List bytes) async {
  final savePath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save Card Image',
    fileName: 'card.png',
    type: FileType.custom,
    allowedExtensions: ['png'],
  );
  if (savePath != null) {
    await File(savePath).writeAsBytes(bytes);
  }
}
