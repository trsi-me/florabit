/// تخزين مؤقت للمستخدم الحالي (في الذاكرة فقط)
class UserProvider {
  static Map<String, dynamic>? currentUser;

  static void setUser(Map<String, dynamic> user) {
    currentUser = user;
  }

  static void clearUser() {
    currentUser = null;
  }

  /// دمج حقول بعد التحديث من الإعدادات أو السيرفر.
  static void mergeUser(Map<String, dynamic> patch) {
    if (currentUser == null) return;
    currentUser!.addAll(patch);
  }

  static int? get userId {
    final v = currentUser?['id'];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
  static String? get userName => currentUser?['name'] as String?;
  static String? get city => currentUser?['city'] as String?;
  static String? get homeType => currentUser?['home_type'] as String?;

  /// موافقة الشروط وسياسة الخصوصية (يُحدَّد من السيرفر).
  static bool get hasAcceptedTermsPrivacy {
    final v = currentUser?['terms_privacy_accepted_at'];
    if (v == null) return false;
    return v.toString().trim().isNotEmpty;
  }

  /// السماح بعرض بيانات النبتة لمن يمسح الباركود دون حساب.
  static bool get plantPublicScanConsent {
    final v = currentUser?['plant_public_scan_consent'];
    if (v is int) return v != 0;
    if (v is bool) return v;
    return false;
  }
}
