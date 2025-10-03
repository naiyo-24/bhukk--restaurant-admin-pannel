// controller/settings/settings_controller.dart
import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  final RxBool notificationsEnabled = true.obs;
  final RxMap<String, bool> notificationPrefs = <String, bool>{
    'order_updates': true,
    'promotions': false,
    'delivery_updates': true,
  }.obs;
  final RxString language = 'English'.obs;

  static const _kNotificationsKey = 'settings_notifications';
  static const _kNotifPrefsKey = 'settings_notification_prefs';


  @override
  void onInit() {
    super.onInit();
    _load();
  }

  void toggleNotifications(bool v) {
    notificationsEnabled.value = v;
    _persist();
  }

  void toggleNotificationPref(String key, bool v) {
    notificationPrefs[key] = v;
    notificationPrefs.refresh();
    _persist();
  }

  void setLanguage(String l) {
  // language is fixed to English in this app; no-op
  }

  void resetDefaults() {
    notificationsEnabled.value = true;
    notificationPrefs.value = {
      'order_updates': true,
      'promotions': false,
      'delivery_updates': true,
    };
  // language remains English
    _persist();
    Get.snackbar('Settings', 'Reset to defaults', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kNotificationsKey, notificationsEnabled.value);
    await sp.setString(_kNotifPrefsKey, jsonEncode(notificationPrefs));
  }

  Future<void> _load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      notificationsEnabled.value = sp.getBool(_kNotificationsKey) ?? notificationsEnabled.value;
      final s = sp.getString(_kNotifPrefsKey);
      if (s != null && s.isNotEmpty) {
        final m = jsonDecode(s) as Map<String, dynamic>;
        notificationPrefs.clear();
        m.forEach((k, v) {
          notificationPrefs[k] = (v as bool);
        });
      }
  // Language is fixed to English; no persisted locale to load.
    } catch (_) {
      // ignore errors and keep defaults
    }
  }
}
