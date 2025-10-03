// IO implementation writing to a downloads/documents directory
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> saveFeedbackCsv(String fileName, String data) async {
  try {
    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {
      // ignore: empty_catches
    }
    dir ??= await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsString(data);
    return path;
  } catch (_) {
    return null;
  }
}
