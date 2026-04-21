import 'package:flutter/material.dart';

import '../api_service.dart';
import '../app_theme.dart';
import '../session_store.dart';
import '../user_provider.dart';

/// شاشة تمنع استخدام التطبيق حتى قبول الشروط واختيار مشاركة الباركود.
class TermsConsentScreen extends StatefulWidget {
  const TermsConsentScreen({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<TermsConsentScreen> createState() => _TermsConsentScreenState();
}

class _TermsConsentScreenState extends State<TermsConsentScreen> {
  bool _acceptedTerms = false;
  bool _publicScan = true;
  bool _submitting = false;

  static const _termsBody = '''
باستخدام فلورابيت فإنك توافق على الشروط والأحكام وسياسة الخصوصية الخاصة بالتطبيق.

• نجمع بيانات الحساب والنباتات التي تدخلها أنت لتشغيل التذكيرات والخريطة والتوصيات.
• يمكن للمسؤول الاطلاع على بيانات المستخدمين ضمن نطاق التشغيل والدعم والامتثال، وفق ما وافقت عليه هنا.
• يمكنك في أي وقت تعديل مشاركة الباركود من الإعدادات.

لمزيد من التفاصيل راجع قسم «حول» في التطبيق.
''';

  Future<void> _submit() async {
    final uid = UserProvider.userId;
    if (uid == null || !_acceptedTerms) return;
    setState(() => _submitting = true);
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await ApiService.updateUser(uid, {
        'terms_privacy_accepted_at': now,
        'plant_public_scan_consent': _publicScan,
      });
      UserProvider.mergeUser({
        'terms_privacy_accepted_at': now,
        'plant_public_scan_consent': _publicScan ? 1 : 0,
      });
      await SessionStore.save(UserProvider.currentUser!);
      if (mounted) widget.onCompleted();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر الحفظ — تحقق من السيرفر'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'الموافقة على الشروط والخصوصية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'للمتابعة يلزم الموافقة على الاستخدام والاطلاع على سياسة الخصوصية.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.85)
                      : scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.25),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _termsBody,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.92)
                            : scheme.onSurface.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                title: Text(
                  'أوافق على الشروط والأحكام وسياسة الخصوصية',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : scheme.onSurface,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _publicScan,
                onChanged: (v) => setState(() => _publicScan = v),
                title: Text(
                  'السماح بعرض معلومات نباتاتي عند مسح الباركود',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : scheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'يُنصح بتفعيله إذا وضعت باركوداً على النبتة لمساعدة الضيوف على الاطلاع والري.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.65)
                        : scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: (!_acceptedTerms || _submitting) ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'موافقة ومتابعة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
