import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../api_service.dart';
import '../app_theme.dart';

/// تقرير عناية لكل نباتات المستخدم مع طباعة/مشاركة PDF (من التطبيق، وليس صفحة الويب).
class CareReportScreen extends StatefulWidget {
  const CareReportScreen({super.key});

  @override
  State<CareReportScreen> createState() => _CareReportScreenState();
}

class _CareReportScreenState extends State<CareReportScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await ApiService.getPlantsCareReport();
      if (mounted) {
        setState(() {
          _data = d;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  String _plainTextReport() {
    final d = _data;
    if (d == null) return '';
    final buf = StringBuffer();
    buf.writeln('فلورابيت — تقرير عناية النباتات');
    buf.writeln('المستخدم: ${d['user_name']}');
    buf.writeln('التاريخ: ${d['generated_at']}');
    buf.writeln('');
    final plants = d['plants'] as List<dynamic>? ?? [];
    if (plants.isEmpty) {
      buf.writeln('لا توجد نباتات.');
      return buf.toString();
    }
    for (final p in plants) {
      final m = p as Map<String, dynamic>;
      buf.writeln('— ${m['name']} (${m['type'] ?? ''})');
      buf.writeln('  آخر ري: ${m['last_watering_date'] ?? '—'} | ملاحظات: ${m['last_watering_notes'] ?? ''}');
      buf.writeln('  آخر تسميد: ${m['last_fertilizing_date'] ?? '—'} | ملاحظات: ${m['last_fertilizing_notes'] ?? ''}');
      buf.writeln('  ملاحظات النبتة: ${m['plant_notes'] ?? ''}');
      buf.writeln('');
    }
    return buf.toString();
  }

  Future<Uint8List> _buildPdfBytes() async {
    final d = _data!;
    final baseData = await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf');
    final baseFont = pw.Font.ttf(baseData);
    final boldFont = pw.Font.ttf(boldData);
    final plants = d['plants'] as List<dynamic>? ?? [];
    final userName = '${d['user_name'] ?? ''}';
    final generated = '${d['generated_at'] ?? ''}';

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
          textDirection: pw.TextDirection.rtl,
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('تقرير عناية النباتات', style: pw.TextStyle(font: boldFont, fontSize: 18)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Text('المستخدم: $userName — $generated', style: pw.TextStyle(font: baseFont, fontSize: 11)),
          ),
          if (plants.isEmpty)
            pw.Text('لا توجد نباتات.', style: pw.TextStyle(font: baseFont))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.4),
                1: const pw.FlexColumnWidth(0.9),
                2: const pw.FlexColumnWidth(1.1),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.1),
                5: const pw.FlexColumnWidth(1.2),
                6: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _pcell('النبتة', boldFont, true),
                    _pcell('النوع', boldFont, true),
                    _pcell('آخر ري', boldFont, true),
                    _pcell('ملاحظات الري', boldFont, true),
                    _pcell('آخر تسميد', boldFont, true),
                    _pcell('ملاحظات التسميد', boldFont, true),
                    _pcell('ملاحظات النبتة', boldFont, true),
                  ],
                ),
                ...plants.map((raw) {
                  final m = raw as Map<String, dynamic>;
                  return pw.TableRow(
                    children: [
                      _pcell('${m['name'] ?? ''}', baseFont, false),
                      _pcell('${m['type'] ?? ''}', baseFont, false),
                      _pcell('${m['last_watering_date'] ?? '—'}', baseFont, false),
                      _pcell('${m['last_watering_notes'] ?? ''}', baseFont, false),
                      _pcell('${m['last_fertilizing_date'] ?? '—'}', baseFont, false),
                      _pcell('${m['last_fertilizing_notes'] ?? ''}', baseFont, false),
                      _pcell('${m['plant_notes'] ?? ''}', baseFont, false),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _pcell(String text, pw.Font font, bool header) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: header ? 9.5 : 8.5),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  Future<void> _printPdf() async {
    if (_data == null) return;
    try {
      final pdfBytes = await _buildPdfBytes();
      if (!mounted) return;
      try {
        final cap = await Printing.info();
        if (cap.canPrint) {
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdfBytes,
            name: 'florabit_care_report.pdf',
            dynamicLayout: false,
          );
          return;
        }
      } catch (e) {
        debugPrint('CareReport layoutPdf: $e');
      }
      final cap = await Printing.info();
      if (cap.canShare) {
        await Printing.sharePdf(bytes: pdfBytes, filename: 'florabit_care_report.pdf');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('اختر تطبيقاً للطباعة أو الحفظ كملف'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      await Share.share(_plainTextReport(), subject: 'تقرير فلورابيت');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إنشاء PDF: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _shareText() async {
    await Share.share(_plainTextReport(), subject: 'تقرير عناية — فلورابيت');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير العناية'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryLight],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        actions: [
          if (_data != null && _error == null) ...[
            IconButton(
              tooltip: 'طباعة PDF',
              icon: const Icon(Icons.print_outlined),
              onPressed: _loading ? null : _printPdf,
            ),
            IconButton(
              tooltip: 'مشاركة نص',
              icon: const Icon(Icons.share_outlined),
              onPressed: _shareText,
            ),
          ],
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: scheme.error),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  ),
                )
              : _buildTable(context),
    );
  }

  Widget _buildTable(BuildContext context) {
    final d = _data!;
    final plants = d['plants'] as List<dynamic>? ?? [];
    final meta = 'المستخدم: ${d['user_name']} — ${d['generated_at']}';
    if (plants.isEmpty) {
      return Center(
        child: Text(meta, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(meta, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
        ),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(AppTheme.primary.withValues(alpha: 0.12)),
                  columns: const [
                    DataColumn(label: Text('النبتة')),
                    DataColumn(label: Text('النوع')),
                    DataColumn(label: Text('آخر ري')),
                    DataColumn(label: Text('ملاحظات الري')),
                    DataColumn(label: Text('آخر تسميد')),
                    DataColumn(label: Text('ملاحظات التسميد')),
                    DataColumn(label: Text('ملاحظات النبتة')),
                  ],
                  rows: plants.map((raw) {
                    final m = raw as Map<String, dynamic>;
                    String v(dynamic x) => x == null || '$x'.trim().isEmpty ? '—' : '$x';
                    return DataRow(
                      cells: [
                        DataCell(Text(v(m['name']))),
                        DataCell(Text(v(m['type']))),
                        DataCell(Text(v(m['last_watering_date']))),
                        DataCell(Text(v(m['last_watering_notes']), maxLines: 3)),
                        DataCell(Text(v(m['last_fertilizing_date']))),
                        DataCell(Text(v(m['last_fertilizing_notes']), maxLines: 3)),
                        DataCell(Text(v(m['plant_notes']), maxLines: 3)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _printPdf,
            icon: const Icon(Icons.print_outlined),
            label: const Text('طباعة التقرير (PDF)'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
