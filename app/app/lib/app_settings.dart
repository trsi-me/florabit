import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const keyCareNotifications = 'florabit_care_notifications';
  static const keyAvatarPath = 'florabit_avatar_path';
  static const keyThemeDark = 'florabit_theme_dark';

  bool _careNotifications = true;
  bool _darkMode = false;
  String? _avatarPath;

  bool get careNotificationsEnabled => _careNotifications;
  bool get darkMode => _darkMode;
  String? get avatarPath => _avatarPath;

  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  /// يفشل أحياناً بعد Hot Restart (قنوات Pigeon) — نتجاهل ونستخدم القيم الافتراضية.
  static Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('AppSettings: SharedPreferences غير متاح — $e');
      return null;
    }
  }

  Future<void> load() async {
    try {
      final p = await _prefs();
      if (p != null) {
        _careNotifications = p.getBool(keyCareNotifications) ?? true;
        _darkMode = p.getBool(keyThemeDark) ?? false;
        _avatarPath = p.getString(keyAvatarPath);
      }
    } catch (e) {
      debugPrint('AppSettings.load: $e');
    }
    notifyListeners();
  }

  Future<void> setCareNotifications(bool value) async {
    _careNotifications = value;
    final p = await _prefs();
    if (p != null) {
      try {
        await p.setBool(keyCareNotifications, value);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final p = await _prefs();
    if (p != null) {
      try {
        await p.setBool(keyThemeDark, value);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> setAvatarPath(String? path) async {
    _avatarPath = path;
    final p = await _prefs();
    if (p != null) {
      try {
        if (path == null || path.isEmpty) {
          await p.remove(keyAvatarPath);
        } else {
          await p.setString(keyAvatarPath, path);
        }
      } catch (_) {}
    }
    notifyListeners();
  }
}
