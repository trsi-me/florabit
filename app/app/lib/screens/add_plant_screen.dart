import 'package:flutter/material.dart';
import '../api_service.dart';
import '../location_helper.dart';
import '../user_provider.dart';
import '../app_theme.dart';

const List<Map<String, String>> ARABIC_PLANTS = [
  {'name': 'بوتس ذهبي', 'type': 'داخلي'},
  {'name': 'صبار', 'type': 'داخلي'},
  {'name': 'نبتة العنكبوت', 'type': 'داخلي'},
  {'name': 'زنبق السلام', 'type': 'داخلي'},
  {'name': 'مونستيرا', 'type': 'داخلي'},
  {'name': 'زاميا', 'type': 'داخلي'},
  {'name': 'فيلوديندرون', 'type': 'داخلي'},
  {'name': 'فيكس مطاطي', 'type': 'داخلي'},
  {'name': 'دراسينا', 'type': 'داخلي'},
  {'name': 'أغلاونيما', 'type': 'داخلي'},
  {'name': 'عصارة خضراء', 'type': 'داخلي'},
  {'name': 'سرخس بوسطن', 'type': 'داخلي'},
  {'name': 'ورود', 'type': 'زينة'},
  {'name': 'خزامى', 'type': 'زينة'},
  {'name': 'إبرة الراعي', 'type': 'زينة'},
  {'name': 'بتونيا', 'type': 'زينة'},
  {'name': 'قطيفة', 'type': 'زينة'},
  {'name': 'ياسمين', 'type': 'زينة'},
  {'name': 'خطمي', 'type': 'زينة'},
  {'name': 'بوجنفيلية', 'type': 'زينة'},
  {'name': 'بيغونيا', 'type': 'زينة'},
  {'name': 'أوركيد', 'type': 'زينة'},
  {'name': 'سيكلامن', 'type': 'زينة'},
  {'name': 'جربيرا', 'type': 'زينة'},
  {'name': 'كروتون', 'type': 'زينة'},
  {'name': 'فيكس بنجامينا', 'type': 'زينة'},
  {'name': 'ريحان', 'type': 'أعشاب'},
  {'name': 'نعناع', 'type': 'أعشاب'},
  {'name': 'إكليل الجبل', 'type': 'أعشاب'},
  {'name': 'زعتر', 'type': 'أعشاب'},
  {'name': 'بقدونس', 'type': 'أعشاب'},
  {'name': 'كزبرة', 'type': 'أعشاب'},
  {'name': 'أوريجانو', 'type': 'أعشاب'},
  {'name': 'مريمية', 'type': 'أعشاب'},
  {'name': 'ثوم معمر', 'type': 'أعشاب'},
  {'name': 'بلسم الليمون', 'type': 'أعشاب'},
];

class AddPlantScreen extends StatefulWidget {
  final String? suggestedName;
  final String? suggestedType;
  final int? wateringDays;
  final int? fertilizingDays;
  final String? suggestedIndoorOutdoor;

  const AddPlantScreen({
    super.key,
    this.suggestedName,
    this.suggestedType,
    this.wateringDays,
    this.fertilizingDays,
    this.suggestedIndoorOutdoor,
  });

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _wateringController;
  late TextEditingController _fertilizingController;
  late String _type;
  late String _indoorOutdoor;
  bool _loading = false;
  bool _locLoading = false;
  double? _lat;
  double? _lng;
  String? _selectedPlant;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.suggestedName ?? '');
    _wateringController = TextEditingController(
      text: (widget.wateringDays ?? 7).toString(),
    );
    _fertilizingController = TextEditingController(
      text: (widget.fertilizingDays ?? 14).toString(),
    );
    _type = widget.suggestedType ?? 'داخلي';
    _indoorOutdoor = widget.suggestedIndoorOutdoor ?? (widget.suggestedType == 'داخلي' ? 'داخلي' : 'خارجي');
    _selectedPlant = widget.suggestedName ?? 'أدخل يدوياً';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wateringController.dispose();
    _fertilizingController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = UserProvider.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final payload = <String, dynamic>{
        'user_id': userId,
        'name': _nameController.text.trim(),
        'type': _type,
        'indoor_outdoor': _indoorOutdoor,
        'watering_interval_days': int.tryParse(_wateringController.text) ?? 7,
        'fertilizing_interval_days':
            int.tryParse(_fertilizingController.text) ?? 14,
      };
      if (_lat != null && _lng != null) {
        payload['latitude'] = _lat;
        payload['longitude'] = _lng;
      }
      await ApiService.createPlant(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('تمت الإضافة'), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ، تحقق من السيرفر')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useMyLocation() async {
    setState(() => _locLoading = true);
    try {
      final pos = await LocationHelper.getCurrentPosition(context);
      if (pos == null) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ إحداثيات الموقع للخريطة'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  void _clearLocation() {
    setState(() {
      _lat = null;
      _lng = null;
    });
  }

  void _onPlantSelected(String? name) {
    setState(() {
      _selectedPlant = name ?? 'أدخل يدوياً';
      if (name != null && name != 'أدخل يدوياً') {
        _nameController.text = name;
        final idx = ARABIC_PLANTS.indexWhere((x) => x['name'] == name);
        if (idx >= 0) {
          _type = ARABIC_PLANTS[idx]['type']!;
          _indoorOutdoor = _type == 'داخلي' ? 'داخلي' : 'خارجي';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('إضافة نبتة'),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('اختر من القائمة أو أدخل يدوياً',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPlant ?? 'أدخل يدوياً',
                decoration: const InputDecoration(
                  labelText: 'اسم النبات',
                  prefixIcon: Icon(Icons.eco),
                ),
                items: [
                  const DropdownMenuItem(
                      value: 'أدخل يدوياً', child: Text('أدخل يدوياً')),
                  ...ARABIC_PLANTS
                      .map((p) => DropdownMenuItem(
                            value: p['name'],
                            child: Text('${p['name']} (${p['type']})'),
                          )),
                ],
                onChanged: _onPlantSelected,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم النبات (أو عدّله أعلاه)',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'أدخل اسم النبات' : null,
                onChanged: (_) => setState(() => _selectedPlant = 'أدخل يدوياً'),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'نوع النبات',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'داخلي', child: Text('داخلي')),
                  DropdownMenuItem(value: 'زينة', child: Text('زينة')),
                  DropdownMenuItem(value: 'أعشاب', child: Text('أعشاب')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _indoorOutdoor,
                decoration: const InputDecoration(
                  labelText: 'التصنيف (داخلي/خارجي) - يمكن التعديل',
                  prefixIcon: Icon(Icons.wb_sunny_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'داخلي', child: Text('داخلي')),
                  DropdownMenuItem(value: 'خارجي', child: Text('خارجي')),
                ],
                onChanged: (v) => setState(() => _indoorOutdoor = v!),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _wateringController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد أيام الري',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 1 ? 'أدخل رقماً صحيحاً' : null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fertilizingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد أيام التسميد',
                  prefixIcon: Icon(Icons.eco_outlined),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 1 ? 'أدخل رقماً صحيحاً' : null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'الموقع على الخريطة (اختياري)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'يُستخدم لعرض النبتة على الخريطة (OpenStreetMap) داخل التطبيق.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _locLoading ? null : _useMyLocation,
                      icon: _locLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 20),
                      label: const Text('استخدام موقعي الحالي'),
                    ),
                  ),
                  if (_lat != null && _lng != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearLocation,
                      icon: const Icon(Icons.close),
                      tooltip: 'إزالة الموقع',
                    ),
                  ],
                ],
              ),
              if (_lat != null && _lng != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'خط العرض: ${_lat!.toStringAsFixed(5)} — خط الطول: ${_lng!.toStringAsFixed(5)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('إضافة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
