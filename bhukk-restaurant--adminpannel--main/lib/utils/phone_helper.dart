// utils/phone_helper.dart
import 'dart:io' show Platform;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:get/get.dart';

/// Helper to launch phone calls with graceful fallbacks and permission handling.
Future<void> launchPhoneCall(BuildContext context, String phone) async {
  final sanitized = phone.replaceAll(RegExp(r"\s+"), '');
  try {
    if (Platform.isAndroid) {
      final status = await Permission.phone.status;
      if (!status.isGranted) {
        final res = await Permission.phone.request();
        if (!res.isGranted) {
          Get.snackbar('Permission', 'Call permission denied');
          return;
        }
      }
      final didCall = await FlutterPhoneDirectCaller.callNumber(sanitized);
      if (didCall == null || didCall == false) {
        final uri = Uri(scheme: 'tel', path: sanitized);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          await Clipboard.setData(ClipboardData(text: sanitized));
          Get.snackbar('Call failed', 'Could not call $sanitized (copied to clipboard)');
        }
      }
      return;
    }

    final uri = Uri(scheme: 'tel', path: sanitized);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await Clipboard.setData(ClipboardData(text: sanitized));
      Get.snackbar('Copied', 'Phone number copied to clipboard');
    }
  } catch (e, st) {
    await Clipboard.setData(ClipboardData(text: sanitized));
    final msg = e is Exception ? e.toString() : '$e';
    Get.snackbar('Call error', '$msg — number copied to clipboard');
    // ignore: avoid_print
    print('[launchPhoneCall] exception: $e\n$st');
  }
}
