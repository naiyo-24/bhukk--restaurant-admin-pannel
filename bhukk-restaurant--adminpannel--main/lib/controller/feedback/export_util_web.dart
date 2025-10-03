// Web implementation using an anchor element download
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String?> saveFeedbackCsv(String fileName, String data) async {
  final blob = html.Blob([data], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a = html.AnchorElement(href: url)..download = fileName;
  html.document.body?.append(a);
  a.click();
  a.remove();
  html.Url.revokeObjectUrl(url);
  return fileName;
}
