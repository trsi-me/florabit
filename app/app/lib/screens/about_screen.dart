import 'package:flutter/material.dart';
import '../app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('عن فلورابيت'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryLight],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.2),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/Logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      color: isDark
                          ? AppTheme.primary.withOpacity(0.25)
                          : AppTheme.cardBg,
                      child: Icon(
                        Icons.eco_rounded,
                        size: 72,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'فلورابيت',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'منصة عربية لرعاية النباتات المنزلية',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: scheme.onSurface.withOpacity(0.72),
              ),
            ),
            const SizedBox(height: 28),
            _SectionCard(
              icon: Icons.auto_awesome_outlined,
              title: 'الرؤية',
              body:
                  'نساعدك على تنظيم ريّ نباتاتك وتسميدها وتتبّع صحتها، مع تذكيرات ذكية وتعرّف على الأنواع بالكاميرا.',
            ),
            const SizedBox(height: 14),
            _SectionCard(
              icon: Icons.layers_outlined,
              title: 'الميزات',
              body:
                  '• قائمة نباتاتك الشخصية\n'
                  '• التعرف على النبات من الصورة\n'
                  '• معرض وتوصيات حسب المناخ\n'
                  '• خريطة تفاعلية لمواقع النباتات (OpenStreetMap)\n'
                  '• تذكيرات العناية على الجهاز\n'
                  '• جلسة تبقى بعد إعادة التشغيل حتى تسجيل الخروج',
            ),
            const SizedBox(height: 14),
            const _TechStackPanel(),
            const SizedBox(height: 32),
            Text(
              'الإصدار 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// حاوية تعرض مكدس التقنيات المستخدمة في فلورابيت.
class _TechStackPanel extends StatelessWidget {
  const _TechStackPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.09),
            AppTheme.primary.withOpacity(0.03),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.terminal_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حاوية التقنية',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'المكدس المستخدم في التطبيق والخادم',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: scheme.onSurface.withOpacity(0.62),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          _TechLine(
            label: 'تطبيق الجوال',
            value: 'Flutter · Dart · Material Design 3 · خط IBM Plex Sans Arabic',
          ),
          _TechLine(
            label: 'الحالة والجلسة',
            value: 'Provider · SharedPreferences · جلسة محلية بعد تسجيل الدخول',
          ),
          _TechLine(
            label: 'الشبكة والوسائط',
            value: 'http · اختيار الصور من المعرض · أذونات الكاميرا والموقع',
          ),
          _TechLine(
            label: 'الخرائط',
            value: 'flutter_map · بلاط OpenStreetMap · latlong2 · Geolocator',
          ),
          _TechLine(
            label: 'التنبيهات',
            value: 'flutter_local_notifications · timezone (توقيت الرياض)',
          ),
          _TechLine(
            label: 'الخادم الخلفي',
            value: 'Python · Flask · REST API · SQLite · تعرّف على النبات (نموذج السيرفر)',
          ),
        ],
      ),
    );
  }
}

class _TechLine extends StatelessWidget {
  const _TechLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, left: 4),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: scheme.onSurface.withOpacity(0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.55,
              color: scheme.onSurface.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}
