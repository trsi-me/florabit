import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يحفظ بيانات المستخدم محلياً لتبقى الجلسة بعد إغلاق التطبيق أو إعادة تشغيل المحاكي
/// (حتى يختار المستخدم «تسجيل الخروج»).
class SessionStore {
  static const _key = 'florabit_user_session';

  static Future<void> save(Map<String, dynamic> user) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(user));
    } catch (e) {
      debugPrint('SessionStore.save: $e');
    }
  }

  static Future<Map<String, dynamic>?> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final id = map['id'];
      if (id == null) return null;
      return map;
    } catch (e) {
      debugPrint('SessionStore.load: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_key);
    } catch (_) {}
  }
}
