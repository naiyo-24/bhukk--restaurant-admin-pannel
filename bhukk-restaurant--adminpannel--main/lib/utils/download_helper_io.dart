// utils/download_helper_io.dart
import 'dart:typed_data';
import 'dart:io';

Future<String?> saveFile(Uint8List bytes, String filename) async {
  final dir = Directory.systemTemp;
  final file = File('${dir.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}
