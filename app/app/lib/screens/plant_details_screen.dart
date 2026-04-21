import 'dart:io';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../api_service.dart';
import '../app_theme.dart';

class PlantDetailsScreen extends StatefulWidget {
  final int plantId;

  const PlantDetailsScreen({super.key, required this.plantId});

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _plant;
  List<dynamic> _logs = [];
  bool _loading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const Map<String, String> _typeGuides = {
    'داخلي': 'النباتات الداخلية تحتاج إضاءة غير مباشرة وتهوية جيدة. تجنب تعريضها لأشعة الشمس المباشرة. نظّف الأوراق بانتظام.',
    'زينة': 'النباتات الزينة تحتاج عناية منتظمة. قلّم الأزهار الذابلة لتشجيع النمو. تأكد من تصريف الماء جيداً.',
    'أعشاب': 'الأعشاب تحتاج ضوءاً كافياً وتربة جيدة التصريف. اسقِ عند جفاف التربة السطحية. قلّم الأوراق لتحفيز النمو.',
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _load();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final plant = await ApiService.getPlant(widget.plantId);
      final logs = await ApiService.getCareLogs(widget.plantId);
      if (mounted) {
        setState(() {
          _plant = plant;
          _logs = logs;
          _loading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _water() async {
    try {
      await ApiService.waterPlant(widget.plantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('تم تسجيل الري'), behavior: SnackBarBehavior.floating),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('حدث خطأ'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _fertilize() async {
    try {
      await ApiService.fertilizePlant(widget.plantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('تم تسجيل التسميد'), behavior: SnackBarBehavior.floating),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('حدث خطأ'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _logLight() async {
    try {
      await ApiService.logLightPlant(widget.plantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('تم تسجيل الإضاءة / الموقع'), behavior: SnackBarBehavior.floating),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('حدث خطأ'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('تفاصيل النبتة'),
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                'جاري التحميل...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_plant == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل النبتة'),
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
        body: const Center(child: Text('لم يتم العثور على النبتة')),
      );
    }
    final p = _plant!;
    final type = p['type'] as String? ?? 'داخلي';
    final guide = _typeGuides[type] ?? _typeGuides['داخلي']!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(p['name'] as String? ?? 'النبتة'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: () => _showBarcodeDialog(context, p),
          ),
        ],
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
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(p, type),
                const SizedBox(height: 16),
                _buildBarcodeCard(p),
                const SizedBox(height: 16),
                _buildCareGuideCard(guide),
                const SizedBox(height: 20),
                _buildActionButtons(),
                const SizedBox(height: 28),
                _buildCareLogs(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _plantBarcodeData() => 'FLR-${widget.plantId}';

  static String _logLabel(String? t) {
    if (t == 'watering') return 'ري';
    if (t == 'fertilizing') return 'تسميد';
    if (t == 'lighting') return 'إضاءة / موقع';
    return t ?? '';
  }

  static IconData _logIcon(String? t) {
    if (t == 'watering') return Icons.water_drop_rounded;
    if (t == 'lighting') return Icons.wb_sunny_outlined;
    return Icons.eco_rounded;
  }

  static Color _logColor(String? t) {
    if (t == 'watering') return Colors.blue.shade700;
    if (t == 'lighting') return Colors.amber.shade800;
    return AppTheme.primary;
  }

  void _showBarcodeDialog(BuildContext context, Map<String, dynamic> p) {
    final name = p['name'] as String? ?? 'النبتة';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: _PlantBarcodeShareDialog(
          plantName: name,
          barcodeData: _plantBarcodeData(),
          onClose: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  Widget _buildBarcodeCard(Map<String, dynamic> p) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTheme.primaryDark;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: () => _showBarcodeDialog(context, p),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: isDark ? Colors.white : AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'باركود النبتة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      'اضغط لعرض الباركود ورمز QR',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.75)
                            : scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : scheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> p, String type) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.category_outlined, 'النوع', type),
          const SizedBox(height: 12),
          _infoRow(Icons.water_drop_outlined, 'فترة الري', 'كل ${p['watering_interval_days']} أيام'),
          _infoRow(Icons.eco_outlined, 'فترة التسميد', 'كل ${p['fertilizing_interval_days']} أيام'),
          const Divider(height: 24),
          _infoRow(Icons.schedule, 'آخر ري', p['last_watering_date'] ?? '-'),
          _infoRow(Icons.schedule, 'آخر تسميد', p['last_fertilizing_date'] ?? '-'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : AppTheme.primary;
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : scheme.onSurface.withValues(alpha: 0.75);
    final valueColor = isDark ? Colors.white : scheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: labelColor,
            fontSize: 15,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: valueColor, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildCareGuideCard(String guide) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? Colors.white : AppTheme.primaryDark;
    final accentIcon = isDark ? Colors.white : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            scheme.surface.withValues(alpha: 0.95),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: isDark ? 0.35 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: accentIcon),
              const SizedBox(width: 8),
              Text(
                'إرشادات العناية',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: headingColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            guide,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: scheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryFg = isDark ? Colors.white : AppTheme.primaryDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Material(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(14),
                elevation: 2,
                child: InkWell(
                  onTap: _water,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.water_drop_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        const Text('تم الري', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Material(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(14),
                elevation: 2,
                child: InkWell(
                  onTap: _fertilize,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 8),
                        const Text('تم التسميد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          elevation: 1,
          child: InkWell(
            onTap: _logLight,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wb_sunny_outlined, color: secondaryFg, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'تسجيل الإضاءة / الموقع',
                    style: TextStyle(
                      color: secondaryFg,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCareLogs() {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سجل العناية',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: isDark ? Colors.white : AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 12),
        if (_logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, color: scheme.onSurface.withValues(alpha: 0.35), size: 28),
                const SizedBox(width: 12),
                Text(
                  'لا يوجد سجل عناية حتى الآن',
                  style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55)),
                ),
              ],
            ),
          )
        else
          ...(_logs.asMap().entries.map((entry) {
            final i = entry.key;
            final l = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (i * 50)),
              curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: child,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _logColor(l['action_type'] as String?).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _logIcon(l['action_type'] as String?),
                        color: _logColor(l['action_type'] as String?),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _logLabel(l['action_type'] as String?),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            l['action_date'] as String? ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          })),
      ],
    );
  }
}

/// حوار الباركود مع مشاركة (أيقونة Share) وطباعة الصورة.
class _PlantBarcodeShareDialog extends StatefulWidget {
  const _PlantBarcodeShareDialog({
    required this.plantName,
    required this.barcodeData,
    required this.onClose,
  });

  final String plantName;
  final String barcodeData;
  final VoidCallback onClose;

  @override
  State<_PlantBarcodeShareDialog> createState() => _PlantBarcodeShareDialogState();
}

class _PlantBarcodeShareDialogState extends State<_PlantBarcodeShareDialog> {
  final GlobalKey _captureKey = GlobalKey();
  final GlobalKey _shareButtonKey = GlobalKey();
  final GlobalKey _printButtonKey = GlobalKey();
  bool _busy = false;

  /// ينتظر اكتمال الرسم ثم يلتقط RepaintBoundary (مهم جداً على iOS ومع BarcodeWidget).
  Future<Uint8List?> _capturePng() async {
    for (var attempt = 0; attempt < 4; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
      if (!mounted) return null;
      final boundary =
          _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || !boundary.hasSize || boundary.size.isEmpty) {
        continue;
      }
      try {
        final ratio = MediaQuery.devicePixelRatioOf(context).clamp(2.0, 4.0);
        final image = await boundary.toImage(pixelRatio: ratio);
        final bd = await image.toByteData(format: ui.ImageByteFormat.png);
        final out = bd?.buffer.asUint8List();
        if (out != null && out.isNotEmpty) return out;
      } catch (e, st) {
        debugPrint('Florabit barcode capture: $e\n$st');
      }
    }
    return null;
  }

  Rect _rectForButton(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final topLeft = box.localToGlobal(Offset.zero);
        return topLeft & box.size;
      }
    }
    final sz = MediaQuery.sizeOf(context);
    final c = Offset(sz.width / 2, sz.height / 2);
    return Rect.fromCenter(center: c, width: 24, height: 24);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await _capturePng();
      if (!mounted) return;
      if (bytes == null) {
        _showSnack('تعذر تجهيز صورة الباركود. أغلق النافذة وافتحها مرة أخرى.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/florabit_barcode_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      final xfile = XFile(
        file.path,
        mimeType: 'image/png',
        name: 'florabit_barcode.png',
      );
      await Share.shareXFiles(
        [xfile],
        text: 'باركود نبتة: ${widget.plantName}',
        sharePositionOrigin: _rectForButton(_shareButtonKey),
      );
    } catch (e, st) {
      debugPrint('Florabit share: $e\n$st');
      if (mounted) {
        _showSnack(
          kDebugMode
              ? 'تعذر المشاركة: $e'
              : 'تعذر المشاركة. جرّب إعادة تشغيل التطبيق أو تحديث النظام.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    setState(() => _busy = true);
    try {
      final bytes = await _capturePng();
      if (!mounted) return;
      if (bytes == null) {
        _showSnack('تعذر تجهيز صورة الباركود للطباعة.');
        return;
      }
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Center(
            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
          ),
        ),
      );
      final pdfBytes = await doc.save();

      // على المحاكي غالباً لا توجد خدمة طباعة — layoutPdf يرمي عبر MethodChannel.
      try {
        final cap = await Printing.info();
        if (cap.canPrint) {
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdfBytes,
            name: 'florabit_barcode.pdf',
            dynamicLayout: false,
          );
          return;
        }
      } catch (e, st) {
        debugPrint('Florabit layoutPdf: $e\n$st');
      }

      if (!mounted) return;

      try {
        final cap = await Printing.info();
        if (cap.canShare) {
          await Printing.sharePdf(
            bytes: pdfBytes,
            filename: 'florabit_barcode.pdf',
            bounds: _rectForButton(_printButtonKey),
            body: 'فلورابيت — ${widget.plantName}',
          );
          _showSnack(
            'لم تُفتح نافذة الطباعة (شائع على المحاكي). اختر تطبيقاً من القائمة للطباعة أو الحفظ.',
          );
          return;
        }
      } catch (e, st) {
        debugPrint('Florabit sharePdf: $e\n$st');
      }

      if (!mounted) return;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/florabit_barcode_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'application/pdf',
            name: 'florabit_barcode.pdf',
          ),
        ],
        text: 'PDF باركود — ${widget.plantName}',
        sharePositionOrigin: _rectForButton(_printButtonKey),
      );
      _showSnack('تم تجهيز ملف PDF — شاركه مع تطبيق يدعم الطباعة أو احفظه.');
    } catch (e, st) {
      debugPrint('Florabit print: $e\n$st');
      if (mounted) {
        _showSnack(
          kDebugMode
              ? 'تعذر الطباعة: $e'
              : 'تعذر الطباعة أو مشاركة PDF. جرّب جهازاً حقيقياً أو حدّث المحاكي.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final outerScheme = Theme.of(context).colorScheme;
    const shareBlue = Color(0xFF1E88E5);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'باركود النبتة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: outerScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const SizedBox(height: 4),
            RepaintBoundary(
              key: _captureKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.plantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const SizedBox(height: 16),
                    BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: widget.barcodeData,
                      width: 250,
                      height: 100,
                      drawText: true,
                      color: Colors.black,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'IBMPlexSansArabic',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data: widget.barcodeData,
                      width: 120,
                      height: 120,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'رمز QR للفحص السريع — فلورابيت',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  key: _shareButtonKey,
                  icon: const Icon(Icons.ios_share_rounded, color: shareBlue, size: 28),
                  tooltip: 'مشاركة',
                  onPressed: _busy ? null : _share,
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  key: _printButtonKey,
                  onPressed: _busy ? null : _print,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('طباعة'),
                ),
                const Spacer(),
                if (_busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
