// controller/common/file_picker_controller.dart
import 'dart:convert';
import 'dart:io' show File;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Centralized file picker helper using GetX, backed by file_selector.
/// XFile works across mobile, desktop, and web with inline implementations.
class FilePickerController extends GetxController {
  static FilePickerController get to => Get.find<FilePickerController>();

  // Last picked single file
  final picked = Rxn<XFile>();

  // Last picked multiple files
  final pickedList = <XFile>[].obs;

  /// Pick a single image.
  Future<XFile?> pickImage() async {
    final typeGroup = const XTypeGroup(label: 'images', extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;
    picked.value = file;
    return file;
  }

  /// Pick multiple images.
  Future<List<XFile>?> pickImages() async {
    final typeGroup = const XTypeGroup(label: 'images', extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp']);
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isEmpty) return null;
    pickedList.assignAll(files);
    return files;
  }

  /// Generic pick (any file) optionally multiple.
  Future<List<XFile>?> pickFiles({bool allowMultiple = false}) async {
    if (allowMultiple) {
      final files = await openFiles();
      if (files.isEmpty) return null;
      pickedList.assignAll(files);
      return files;
    } else {
      final file = await openFile();
      if (file == null) return null;
      picked.value = file;
      return [file];
    }
  }

  /// Read bytes from XFile
  Future<Uint8List?> readBytes(XFile xf) async {
    try {
      return await xf.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  /// Convert to data URL (best-effort; assumes image/* if extension matches)
  Future<String?> toDataUrl(XFile xf) async {
    try {
      final bytes = await readBytes(xf);
      if (bytes == null) return null;
      final ext = xf.name.split('.').last.toLowerCase();
      final kind = ['png','jpg','jpeg','gif','webp','bmp','wbmp'].contains(ext) ? 'image/$ext' : 'application/octet-stream';
      final base64Str = base64Encode(bytes);
      return 'data:$kind;base64,$base64Str';
    } catch (_) {
      return null;
    }
  }

  /// Get a native File path if available (mobile/desktop); returns null on web.
  File? toNativeFile(XFile xf) {
    if (kIsWeb) return null;
    return File(xf.path);
  }
}
